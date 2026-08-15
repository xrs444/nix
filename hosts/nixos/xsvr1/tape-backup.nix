# Ad-hoc, manually-triggered air-gapped backup of /zfs/documents to the
# StorageWorks 1760 (LTO-4) SAS tape drive. This is a THIRD backup tier on
# top of the automated ones (ZFS replication to xsvr2 via replication.nix,
# then offsite restic to Synology via xsvr2/offsite-backup.nix) — both of
# those are networked and could in principle be compromised together. Tape
# is only useful here if it's genuinely air-gapped, so:
#   - it is NOT scheduled (a human has to load the tape anyway)
#   - the age decryption private key NEVER lives on this host — only the
#     public key is baked in below. Without the private key this host
#     cannot read back what it just wrote.
#
# One-time setup:
#   1. On an OFFLINE machine: age-keygen -o tape-backup-key.txt
#   2. Take the "# public key: age1..." line and set ageRecipient below.
#   3. Store tape-backup-key.txt with the tapes (e.g. in the bank box), not
#      on any networked machine.
#
# Usage:
#   systemctl start tape-backup-documents.service   # write a tape
#   journalctl -u tape-backup-documents.service      # check the result
#   tape-restore-documents <key-file> --list-only    # verify without extracting
#   tape-restore-documents <key-file> <dest-dir>     # full restore
{ pkgs, ... }:
let
  ageRecipient = "age1REPLACEME"; # see setup instructions above

  tapeDevice = "/dev/nst0"; # non-rewind SCSI tape

  manifestDir = "/var/lib/tape-backup/manifests";

  tapeTools = [
    pkgs.gnutar
    pkgs.zstd
    pkgs.age
    pkgs.mbuffer
    pkgs.mt-st
  ];

  tapeBackupDocuments = pkgs.writeShellApplication {
    name = "tape-backup-documents";
    runtimeInputs = tapeTools ++ [ pkgs.coreutils ];
    text = ''
      if [ ! -e "${tapeDevice}" ]; then
        echo "ERROR: ${tapeDevice} not found. Check the drive is powered on and" \
             "cabled, and that a tape is loaded (try: lsscsi -g)." >&2
        exit 1
      fi

      echo "Tape status:"
      mt -f "${tapeDevice}" status

      mkdir -p "${manifestDir}"
      manifest="${manifestDir}/documents-$(date +%Y%m%d-%H%M%S).txt"

      echo "Rewinding tape..."
      mt -f "${tapeDevice}" rewind

      echo "Writing /zfs/documents to tape (compressed, then encrypted)..."
      echo "File manifest: $manifest"
      tar -cvf - -C /zfs documents 2>"$manifest" \
        | zstd -T0 \
        | age -r "${ageRecipient}" \
        | mbuffer -m 512M -o "${tapeDevice}"

      echo "Writing end-of-file mark and rewinding..."
      mt -f "${tapeDevice}" weof 1
      mt -f "${tapeDevice}" rewind

      echo "Done. Manifest saved to $manifest (filenames only, no file"
      echo "contents, safe to keep on xsvr1). Label the tape and store it"
      echo "off-site. This host cannot verify or restore this tape — the"
      echo "decryption key is intentionally not present here. Use"
      echo "tape-restore-documents on a machine with the private key."
    '';
  };

  tapeRestoreDocuments = pkgs.writeShellApplication {
    name = "tape-restore-documents";
    runtimeInputs = tapeTools ++ [ pkgs.coreutils ];
    text = ''
      if [ $# -lt 1 ]; then
        echo "Usage: tape-restore-documents <age-private-key-file> [dest-dir | --list-only]" >&2
        exit 1
      fi
      key="$1"
      mode="''${2:---list-only}"

      mt -f "${tapeDevice}" rewind

      if [ "$mode" = "--list-only" ]; then
        mbuffer -m 512M -i "${tapeDevice}" | age -d -i "$key" | zstd -d | tar -tvf -
      else
        dest="$mode"
        mkdir -p "$dest"
        mbuffer -m 512M -i "${tapeDevice}" | age -d -i "$key" | zstd -d | tar -xvf - -C "$dest"
        echo "Restored to $dest"
      fi
    '';
  };
in
{
  boot.kernelModules = [ "st" ];

  environment.systemPackages = tapeTools ++ [
    pkgs.lsscsi
    tapeBackupDocuments
    tapeRestoreDocuments
  ];

  systemd.services.tape-backup-documents = {
    description = "Ad-hoc air-gapped backup of /zfs/documents to LTO tape (manual trigger only)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${tapeBackupDocuments}/bin/tape-backup-documents";
    };
    # No wantedBy/startAt on purpose — trigger by hand:
    #   systemctl start tape-backup-documents.service
  };
}

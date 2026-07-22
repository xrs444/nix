# Summary: Table-driven Syncthing device/folder declaration, keyed by username. Reusable per-user
# (e.g. a future Samantha entry) without duplicating logic — see the "obsidian vault" plan doc.
{
  pkgs,
  lib,
  username,
  ...
}:
let
  # Per-user vault mesh definitions. Add a user's entry here (and import this
  # file from their homemanager/users/<name>/default.nix) to onboard them —
  # no duplicated Syncthing logic needed. Only xrs444 is populated today; a
  # future `samantha = { ... };` entry (her own folder/device set) is the
  # whole diff needed to bring her onto the same pattern.
  vaultMeshes = {
    xrs444 = {
      folderId = "xrs444-obsidian";
      folderLabel = "Obsidian";
      # Confirmed live 2026-07-21 via the Syncthing GUI on xlt1-t: the
      # folder's local path there is literally `~/Documents/Obsidian/xrs444`
      # (note the nested "xrs444" segment and capital O — macOS's default
      # case-insensitive filesystem means the capitalization doesn't matter
      # functionally, but this matches the confirmed live value exactly).
      # xdt1-t's path is a separate, independent local choice (no existing
      # data there yet, so no matching requirement) carried over unchanged
      # from the prior host-level syncthing.nix.
      folderPath =
        if pkgs.stdenv.isDarwin then
          "/Users/${username}/Documents/Obsidian/${username}"
        else
          "/home/${username}/Documents/obsidian";
      # Device IDs are public keys, not secrets — safe to commit in plain text.
      devices = {
        xsvr1 = {
          id = "BMTUKUC-2EHB5GN-WTM2QFG-WMGNNUC-3EBYPX7-BTHGYX5-7C6SU72-FAEU7AI";
          # xsvr1 is the mesh hub/introducer on every existing member's config.
          introducer = true;
        };
        xlt1-t = {
          id = "KR5364I-V6A6WVX-JXQS3XX-IQROL3Q-E654SM3-UVYOZZ3-L5XMEQ7-IOUHKQV";
        };
        # xdt1-t's full device ID — fill in once confirmed (short form
        # IQ2OA2T seen in xsvr1's pod logs is truncated, not usable here).
        xdt1-t = {
          id = "IQ2OA2T-XE3O23R-FDHNVHS-KTM35FF-Q3ZMZYS-BMS4RLP-GIN5PLB-APVJ7QK";
        };
        munin = {
          # The phone. Out-of-band device (no nix/flux management), just
          # registered here so it's trusted on every nix-managed host.
          id = "X4L5ZWN-HCUKYPU-J2Q77M3-E5R5IHF-CL3UGUN-IMDOZRU-U6BZNYF-TINVTQD";
        };
      };
    };
  };

  mesh = vaultMeshes.${username} or null;
in
lib.mkIf (mesh != null) {
  services.syncthing = {
    enable = true;
    # Reconcile the declared device/folder list via the REST config API on
    # every activation (drift correction) — same semantics as the old
    # NixOS-only module this supersedes. Deliberately no `configDir`/`cert`/
    # `key` option is set: the module's own built-in path-detection
    # (Darwin: ~/Library/Application Support/Syncthing; Linux: prefers
    # whichever of ~/.local/state/syncthing or ~/.config/syncthing already
    # has a config.xml) already lands on each host's existing identity
    # location with zero extra config — that's what preserves the existing
    # device IDs (KR5364I on xlt1-t, IQ2OA2T on xdt1-t) across this switch.
    overrideDevices = true;
    overrideFolders = true;
    guiAddress = "127.0.0.1:8384";
    settings = {
      devices = mesh.devices;
      folders.${mesh.folderId} = {
        label = mesh.folderLabel;
        devices = builtins.attrNames mesh.devices;
        path = mesh.folderPath;
      };
    };
  };
}

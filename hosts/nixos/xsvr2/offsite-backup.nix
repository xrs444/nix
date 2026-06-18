# Offsite backup for xsvr2 — restic via SFTP to Synology
#
# Backs up critical datasets received from xsvr1 replication.
# Rate limited to 10 Mbps (1.25 MiB/s) to leave headroom on 30 Mbps WAN.
# Initial seed (~300 GB) will take ~67 days at full rate — restic is resumable.
#
# Prerequisites (one-time manual steps):
#   1. Create sops secret file:
#        sops nix/secrets/restic-offsite.yaml
#      Add keys: password (restic repo password), ssh_key (ed25519 private key)
#   2. On Synology: create user 'restic', enable SSH, add public key
#   3. Update synologyHost below to the actual Synology FQDN/IP
#   4. Initialize repo on first run:
#        restic -r sftp:restic@<synology-host>:/volume1/restic-xsvr2 init
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Set to true after:
  #   1. Adding restic_offsite_password + restic_offsite_ssh_key to nix/secrets/secrets.yaml
  #   2. Setting up Synology SSH user and authorized_keys
  #   3. Updating synologyHost below
  enabled = true;

  # Update this to the Synology's actual hostname or IP
  synologyHost = "cmrnas.xrs444.net";
  synologyUser = "restic";
  repoPath = "/home/restic-xsvr2";
in
lib.mkIf enabled {
  # SSH config for root so restic's sftp transport picks up the identity key without
  # passing -i on the command line (the NixOS restic module doesn't quote extraOptions,
  # so space-delimited sftp.args values get word-split and break restic's arg parser).
  programs.ssh.extraConfig = ''
    Host ${synologyHost}
      IdentityFile /run/secrets/restic-offsite-ssh-key
      StrictHostKeyChecking accept-new
      BatchMode yes
  '';

  # Before deploying, add these two keys to nix/secrets/secrets.yaml:
  #   sops nix/secrets/secrets.yaml
  #   restic_offsite_password: <strong random repo password>
  #   restic_offsite_ssh_key: |
  #     -----BEGIN OPENSSH PRIVATE KEY-----
  #     <ed25519 private key for Synology>
  #     -----END OPENSSH PRIVATE KEY-----
  #
  # Generate the key pair:
  #   ssh-keygen -t ed25519 -f /tmp/restic-synology -N "" -C "restic@xsvr2"
  #   cat /tmp/restic-synology      → restic_offsite_ssh_key value
  #   cat /tmp/restic-synology.pub  → add to Synology restic user authorized_keys
  sops.secrets.restic-offsite-password = {
    sopsFile = ../../../secrets/restic-xsvr2.yaml;
    key = "restic_offsite_password";
    owner = "root";
    mode = "0400";
  };

  sops.secrets.restic-offsite-ssh-key = {
    sopsFile = ../../../secrets/restic-xsvr2.yaml;
    key = "restic_offsite_ssh_key";
    owner = "root";
    mode = "0400";
  };

  services.restic.backups.offsite = {
    # Datasets replicated from xsvr1 — verify mountpoints on xsvr2
    paths = [
      "/zfs/systembackups"
      "/zfs/devicebackups"
      "/zfs/googlebackups"
      "/zfs/documents"
      "/zfs/users"
      "/zfs/system"
      "/zfs/media/books"
      "/zfs/timemachine"
    ];

    repository = "sftp:${synologyUser}@${synologyHost}:${repoPath}";
    passwordFile = config.sops.secrets.restic-offsite-password.path;

    # Daily at 02:00; Persistent so it runs after downtime
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };

    # 7 daily, 4 weekly, 6 monthly — keeps ~9 months of history without unbounded growth
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    extraBackupArgs = [
      # 10 Mbps = 1.25 MiB/s — leaves 20 Mbps headroom on 30 Mbps WAN
      "--limit-upload 1280"
      # Time Machine sparse bundles have large internal structure — exclude trash
      "--exclude=/zfs/timemachine/.Trash*"
    ];

    # Initialize the repository on first run if it doesn't exist
    initialize = true;
  };

  # Progress logging: reduce restic's default 0.5s update interval to once per minute
  # so journals aren't flooded during the initial seed transfer
  systemd.services."restic-backups-offsite".environment = {
    RESTIC_PROGRESS_FPS = "0.016";
  };

  environment.systemPackages = [ pkgs.restic ];
}

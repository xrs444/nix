# ZFS Replication Configuration for xsvr1 (Source Host)
# Replicates critical datasets to xsvr2 for redundancy
{ pkgs, ... }:
{
  # Import the ZFS replication module
  imports = [
    ../../../modules/services/zfs/replication.nix
  ];

  # Configure sops secret for syncoid SSH key
  sops.secrets.syncoid-private-key = {
    sopsFile = ../../../secrets/syncoid-ssh-key.yaml;
    key = "syncoid_private_key";
    owner = "syncoid";
    group = "syncoid";
    mode = "0600";
    path = "/var/lib/syncoid/.ssh/id_ed25519";
  };

  # Disable automatic SSH key generation since we're using sops
  systemd.services.syncoid-ssh-keygen.enable = false;

  # Create SSH directory and public key from sops
  systemd.services.syncoid-ssh-setup = {
    description = "Setup Syncoid SSH keys from sops";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/syncoid/.ssh
      chown syncoid:syncoid /var/lib/syncoid/.ssh
      chmod 700 /var/lib/syncoid/.ssh

      # Extract public key from private key
      ${pkgs.openssh}/bin/ssh-keygen -y -f /var/lib/syncoid/.ssh/id_ed25519 > /var/lib/syncoid/.ssh/id_ed25519.pub
      chown syncoid:syncoid /var/lib/syncoid/.ssh/id_ed25519.pub
      chmod 644 /var/lib/syncoid/.ssh/id_ed25519.pub
    '';
  };

  # Enable ZFS replication
  services.zfsReplication = {
    enable = true;

    # Datasets to replicate from xsvr1 to xsvr2
    sourceDatasets = [
      "zpool-xsvr1/systembackups" # Longhorn and system backups
      "zpool-xsvr1/devicebackups" # Device backups
      "zpool-xsvr1/googlebackups" # Google backups
    ];

    # Target host for replication
    targetHost = "xsvr2.lan";

    # Replication runs every hour
    interval = "hourly";
  };

  # Sanoid snapshot configuration
  services.sanoid = {
    enable = true;

    datasets = {
      # System backups (Longhorn, etc.) - frequent snapshots, shorter retention
      "zpool-xsvr1/systembackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };

      # Device backups - daily snapshots, longer retention
      "zpool-xsvr1/devicebackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };

      # Google backups - daily snapshots, longer retention
      "zpool-xsvr1/googlebackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
    };

    templates = {
      backup = {
        hourly = 24; # Keep 24 hourly snapshots (1 day)
        daily = 7; # Keep 7 daily snapshots (1 week)
        weekly = 4; # Keep 4 weekly snapshots (1 month)
        monthly = 3; # Keep 3 monthly snapshots (3 months)
        autosnap = true;
        autoprune = true;
      };
    };
  };
}

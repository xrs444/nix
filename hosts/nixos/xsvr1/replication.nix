# ZFS Replication Configuration for xsvr1 (Source Host)
# Replicates critical datasets to xsvr2 for redundancy
{
  # Import the ZFS replication module
  imports = [
    ../../../modules/services/zfs/replication.nix
  ];

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

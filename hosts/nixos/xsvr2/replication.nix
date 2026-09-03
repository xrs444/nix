# ZFS Replication Configuration for xsvr2 (Target Host)
# Receives replicated datasets from xsvr1
{
  # Import the ZFS replication module
  imports = [
    ../../../modules/services/zfs/replication.nix
  ];

  # Configure sops secret to read the public key
  sops.secrets.syncoid-public-key = {
    sopsFile = ../../../secrets/syncoid-ssh-key.yaml;
    key = "syncoid_public_key";
  };

  # Enable ZFS replication as target
  services.zfsReplication = {
    enable = true;

    # SSH public key from sops secret
    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqkKlOzh/vBBtSh39UpdadSng9CVf3e6WfbUE0bp4cg syncoid@xsvr1";
  };

  # Create parent container datasets that syncoid cannot create automatically.
  # zpool-xsvr2-media/media must exist before receiving media/movies, media/tvshows, etc.
  systemd.services.syncoid-target-create-parents = {
    description = "Create parent container datasets for syncoid receive on xsvr2";
    wantedBy = [ "multi-user.target" ];
    after = [ "zfs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      /run/current-system/sw/bin/zfs create -o mountpoint=/zfs/media zpool-xsvr2-media/media 2>/dev/null || true
    '';
  };

  # Prune replicated snapshots on the target. syncoid only ever receives here —
  # nothing on this host was expiring snapshots, so 49,043 accumulated (410GiB)
  # since replication started. Templates mirror xsvr1/replication.nix's source
  # policy so the target never retains more history than the source intends.
  services.sanoid = {
    enable = true;

    datasets = {
      "zpool-xsvr2/systembackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr2/devicebackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr2/googlebackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr2/documents" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr2/users" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr2/media/books" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr2/system" = {
        useTemplate = [ "system" ];
        recursive = true;
      };
      "zpool-xsvr2/timemachine" = {
        useTemplate = [ "timemachine" ];
        recursive = true;
      };
      "zpool-xsvr2-media/media/movies" = {
        useTemplate = [ "media" ];
        recursive = false;
      };
      "zpool-xsvr2-media/media/tvshows" = {
        useTemplate = [ "media" ];
        recursive = false;
      };
      "zpool-xsvr2-media/media/music" = {
        useTemplate = [ "media" ];
        recursive = false;
      };
      "zpool-xsvr2-media/media/audiobooks" = {
        useTemplate = [ "media" ];
        recursive = true;
      };
      "zpool-xsvr2-media/media/games" = {
        useTemplate = [ "media" ];
        recursive = true;
      };
      "zpool-xsvr2-media/ingest" = {
        useTemplate = [ "ingest" ];
        recursive = true;
      };
      "zpool-xsvr2-media/scan" = {
        useTemplate = [ "ingest" ];
        recursive = true;
      };
    };

    templates = {
      backup = {
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 3;
        autosnap = false; # target only prunes; snapshots originate on xsvr1
        autoprune = true;
      };
      media = {
        hourly = 0;
        daily = 3;
        weekly = 2;
        monthly = 1;
        autosnap = false;
        autoprune = true;
      };
      system = {
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 3;
        autosnap = false;
        autoprune = true;
      };
      ingest = {
        hourly = 6;
        daily = 3;
        weekly = 0;
        monthly = 0;
        autosnap = false;
        autoprune = true;
      };
      timemachine = {
        hourly = 0;
        daily = 7;
        weekly = 4;
        monthly = 1;
        autosnap = false;
        autoprune = true;
      };
    };
  };
}

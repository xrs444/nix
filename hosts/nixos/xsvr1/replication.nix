# ZFS Replication Configuration for xsvr1 (Source Host)
# Replicates critical datasets to xsvr2 for redundancy
# Pool: zpool-xsvr1-main (2x22TB Seagate Exos mirror)
# Phase 5 will refactor services.zfsReplication to the jobs API with targetPool mapping.
{ pkgs, ... }:
{
  # Import the ZFS replication module
  imports = [
    ../../../modules/services/zfs/replication.nix
  ];

  # Configure sops secret for syncoid SSH key (no path, just extract to default location)
  sops.secrets.syncoid-private-key = {
    sopsFile = ../../../secrets/syncoid-ssh-key.yaml;
    key = "syncoid_private_key";
  };

  # Disable automatic SSH key generation since we're using sops
  systemd.services.syncoid-ssh-keygen.enable = false;

  # Install syncoid SSH key from sops during activation.
  # sops-nix populates /run/secrets/ via its own activation script, which runs
  # before this one. Using activationScripts (not a systemd service) guarantees
  # the key is in place before any replication services start — no ordering
  # dependencies required.
  system.activationScripts.syncoid-ssh-setup = {
    deps = [ "users" "groups" ];
    text = ''
      key_src="/run/secrets/syncoid-private-key"
      ssh_dir="/var/lib/syncoid/.ssh"

      if [ ! -f "$key_src" ]; then
        echo "syncoid-ssh-setup: $key_src not found, skipping"
        exit 0
      fi

      install -d -o syncoid -g syncoid -m 700 "$ssh_dir"
      install -o syncoid -g syncoid -m 600 "$key_src" "$ssh_dir/id_ed25519"
      ${pkgs.openssh}/bin/ssh-keygen -y -f "$ssh_dir/id_ed25519" \
        | install -o syncoid -g syncoid -m 644 /dev/stdin "$ssh_dir/id_ed25519.pub"
    '';
  };

  # ZFS replication to xsvr2 — two jobs splitting critical vs media across pools.
  # Critical data goes to zpool-xsvr2 (younger 2TB drives).
  # Media goes to zpool-xsvr2-media (5x3TB from xsvr1 — Phase 4, pending drive connectivity fix).
  services.zfsReplication = {
    enable = true;

    jobs = {
      critical = {
        sourceDatasets = [
          "zpool-xsvr1-main/systembackups"
          "zpool-xsvr1-main/devicebackups"
          "zpool-xsvr1-main/googlebackups"
          "zpool-xsvr1-main/documents"
          "zpool-xsvr1-main/users"
          "zpool-xsvr1-main/system"
          "zpool-xsvr1-main/media/books"
          "zpool-xsvr1-main/timemachine"
        ];
        targetHost = "xsvr2.lan";
        targetPool = "zpool-xsvr2";
        interval = "hourly";
      };

      media = {
        sourceDatasets = [
          "zpool-xsvr1-main/media/movies"
          "zpool-xsvr1-main/media/tvshows"
          "zpool-xsvr1-main/media/music"
          "zpool-xsvr1-main/media/audiobooks"
          "zpool-xsvr1-main/media/games"
          "zpool-xsvr1-main/ingest"
          "zpool-xsvr1-main/scan"
        ];
        targetHost = "xsvr2.lan";
        targetPool = "zpool-xsvr2-media";
        interval = "hourly";
      };
    };
  };

  # Sanoid snapshot configuration
  services.sanoid = {
    enable = true;

    datasets = {
      # Backups and critical data — replicated to xsvr2
      "zpool-xsvr1-main/systembackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr1-main/devicebackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr1-main/googlebackups" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr1-main/documents" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
      "zpool-xsvr1-main/users" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };

      # Book library — replicated to xsvr2
      "zpool-xsvr1-main/media/books" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };

      # Media — changes infrequently after import; daily snapshots sufficient
      "zpool-xsvr1-main/media/movies" = {
        useTemplate = [ "media" ];
        recursive = false;
      };
      "zpool-xsvr1-main/media/tvshows" = {
        useTemplate = [ "media" ];
        recursive = false;
      };
      "zpool-xsvr1-main/media/music" = {
        useTemplate = [ "media" ];
        recursive = false;
      };
      "zpool-xsvr1-main/media/audiobooks" = {
        useTemplate = [ "media" ];
        recursive = true;
      };
      "zpool-xsvr1-main/media/games" = {
        useTemplate = [ "media" ];
        recursive = true;
      };

      # VM — high churn, short retention; Talos VMs are declarative/rebuildable
      "zpool-xsvr1-main/vm" = {
        useTemplate = [ "vm" ];
        recursive = false;
      };

      # App system data — database-like, frequent snapshots
      "zpool-xsvr1-main/system" = {
        useTemplate = [ "system" ];
        recursive = true;
      };

      # Ingest and transient staging — short retention
      "zpool-xsvr1-main/ingest" = {
        useTemplate = [ "ingest" ];
        recursive = true;
      };
      "zpool-xsvr1-main/scan" = {
        useTemplate = [ "ingest" ];
        recursive = true;
      };
      "zpool-xsvr1-main/nixcache" = {
        useTemplate = [ "ingest" ];
        recursive = false;
      };

      # Time Machine — manages its own versioning; daily snapshots only
      "zpool-xsvr1-main/timemachine" = {
        useTemplate = [ "timemachine" ];
        recursive = true;
      };

      # OldDataToOrganize — excluded: transient, unstructured, not worth snapshotting
    };

    templates = {
      # Critical data replicated to xsvr2
      backup = {
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 3;
        autosnap = true;
        autoprune = true;
      };

      # Media library — rarely changes post-import
      media = {
        hourly = 0;
        daily = 3;
        weekly = 2;
        monthly = 1;
        autosnap = true;
        autoprune = true;
      };

      # VM disks — high churn, Longhorn provides in-cluster replication
      vm = {
        hourly = 6;
        daily = 3;
        weekly = 1;
        monthly = 0;
        autosnap = true;
        autoprune = true;
      };

      # App system data (Crafty, Matrix)
      system = {
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 3;
        autosnap = true;
        autoprune = true;
      };

      # Ingest/staging — transient; keep just enough for recovery from bad imports
      ingest = {
        hourly = 6;
        daily = 3;
        weekly = 0;
        monthly = 0;
        autosnap = true;
        autoprune = true;
      };

      # Time Machine — TM manages its own versioning internally
      timemachine = {
        hourly = 0;
        daily = 7;
        weekly = 4;
        monthly = 1;
        autosnap = true;
        autoprune = true;
      };
    };
  };
}

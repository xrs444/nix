# Summary: ZFS replication module using Syncoid for dataset replication between hosts
{
  config,
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.zfsReplication;
  hasZfsRole = lib.elem "zfs" hostRoles;
  isReplicationSource = lib.elem "zfs-replication-source" hostRoles;
  isReplicationTarget = lib.elem "zfs-replication-target" hostRoles;

  # SSH key paths
  sshKeyPath = "/var/lib/syncoid/.ssh/id_ed25519";
  sshPubKeyPath = "\${sshKeyPath}.pub";

  # Generate syncoid command for a dataset
  mkSyncoidCommand = dataset: target: ''
    \${pkgs.sanoid}/bin/syncoid \
      --no-privilege-elevation \
      --sshkey \${sshKeyPath} \
      \${dataset} \
      \${target}:\${dataset}
  '';
in
{
  options.services.zfsReplication = {
    enable = lib.mkEnableOption "ZFS replication via Syncoid";

    sourceDatasets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of ZFS datasets to replicate from this host";
      example = [
        "zpool-xsvr1/data"
        "zpool-xsvr1/backups"
      ];
    };

    targetHost = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Target host for replication (SSH hostname or IP)";
      example = "xsvr2";
    };

    targetUser = lib.mkOption {
      type = lib.types.str;
      default = "syncoid";
      description = "SSH user on target host for replication";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "How often to run replication (systemd timer interval)";
      example = "hourly";
    };

    sshPublicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Public SSH key for the target host to authorize (set on source)";
    };
  };

  config = lib.mkMerge [
    # Source host configuration (where data originates)
    (lib.mkIf (hasZfsRole && isReplicationSource && cfg.enable) {
      # Create syncoid user for running replication
      users.users.syncoid = {
        isSystemUser = true;
        group = "syncoid";
        description = "ZFS replication user";
        home = "/var/lib/syncoid";
        createHome = true;
        shell = pkgs.bashInteractive;
      };

      users.groups.syncoid = { };

      # Generate SSH key for syncoid user
      systemd.services.syncoid-ssh-keygen = {
        description = "Generate SSH key for Syncoid";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "syncoid";
          Group = "syncoid";
          RemainAfterExit = true;
        };
        script = ''
          if [ ! -f \${sshKeyPath} ]; then
            mkdir -p \$(dirname \${sshKeyPath})
            \${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f \${sshKeyPath} -N "" -C "syncoid@\${hostname}"
            chmod 600 \${sshKeyPath}
            chmod 644 \${sshPubKeyPath}
            echo "Generated SSH key for syncoid at \${sshKeyPath}"
            echo "Public key:"
            cat \${sshPubKeyPath}
          fi
        '';
      };

      # Grant syncoid user necessary ZFS permissions
      systemd.services.syncoid-zfs-permissions = {
        description = "Grant ZFS permissions to Syncoid user";
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = lib.concatMapStringsSep "\n" (dataset: ''
          \${pkgs.zfs}/bin/zfs allow syncoid send,snapshot,hold \${dataset} || true
        '') cfg.sourceDatasets;
      };

      # Replication service
      systemd.services.zfs-replication = {
        description = "ZFS replication to \${cfg.targetHost}";
        after = [
          "network-online.target"
          "zfs.target"
          "syncoid-ssh-keygen.service"
          "syncoid-zfs-permissions.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "syncoid";
          Group = "syncoid";
        };
        path = with pkgs; [
          zfs
          sanoid
          openssh
          gawk
          util-linux
          pv
          lzop
          mbuffer
        ];
        script = ''
          set -e

          # Ensure SSH key exists
          if [ ! -f \${sshKeyPath} ]; then
            echo "ERROR: SSH key not found at \${sshKeyPath}"
            echo "Run: systemctl start syncoid-ssh-keygen"
            exit 1
          fi

          # Test SSH connectivity
          echo "Testing SSH connection to \${cfg.targetUser}@\${cfg.targetHost}..."
          \${pkgs.openssh}/bin/ssh -i \${sshKeyPath} \
            -o StrictHostKeyChecking=no \
            -o BatchMode=yes \
            \${cfg.targetUser}@\${cfg.targetHost} \
            "echo 'SSH connection successful'" || {
            echo "ERROR: Cannot connect to \${cfg.targetUser}@\${cfg.targetHost}"
            exit 1
          }

          # Replicate each dataset
          \${
            lib.concatMapStringsSep "\n" (
              dataset:
              let
                target = "\${cfg.targetUser}@\${cfg.targetHost}";
              in
              ''
                echo "Replicating \${dataset} to \${cfg.targetHost}..."
                \${mkSyncoidCommand dataset target}
              ''
            ) cfg.sourceDatasets
          }

          echo "Replication completed successfully"
        '';
      };

      # Timer for automatic replication
      systemd.timers.zfs-replication = {
        description = "Timer for ZFS replication";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.interval;
          Persistent = true;
          RandomizedDelaySec = "5m";
        };
      };

      # Add sanoid package to system
      environment.systemPackages = with pkgs; [
        sanoid
        zfs
      ];
    })

    # Target host configuration (where data is received)
    (lib.mkIf (hasZfsRole && isReplicationTarget && cfg.enable) {
      # Create syncoid user for receiving replication
      users.users.syncoid = {
        isSystemUser = true;
        group = "syncoid";
        description = "ZFS replication user";
        home = "/var/lib/syncoid";
        createHome = true;
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = lib.optional (cfg.sshPublicKey != null) cfg.sshPublicKey;
      };

      users.groups.syncoid = { };

      # Grant syncoid user necessary ZFS permissions on target
      systemd.services.syncoid-target-zfs-permissions = {
        description = "Grant ZFS permissions to Syncoid user on target";
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Grant receive permissions - syncoid needs these on the target pool
          # Grant on all pools since we don't know which datasets will be replicated
          for pool in $(${pkgs.zfs}/bin/zpool list -H -o name); do
            ${pkgs.zfs}/bin/zfs allow syncoid \
              compression,create,destroy,mount,mountpoint,receive,rollback,snapshot,hold \
              "$pool" || true
          done
        '';
      };

      # Add sanoid package to system
      environment.systemPackages = with pkgs; [
        sanoid
        zfs
      ];
    })
  ];
}

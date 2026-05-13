# ZFS Replication Module using Syncoid
#
# Supports multiple independent replication jobs, each targeting a different
# pool on the remote host. Pool names are remapped automatically:
#   source: zpool-xsvr1-main/systembackups
#   target: zpool-xsvr2/systembackups  (sourcePool replaced by job.targetPool)
#
# Source host: configure services.zfsReplication.jobs
# Target host: configure services.zfsReplication.sshPublicKey
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.zfsReplication;
  sshKeyPath = "/var/lib/syncoid/.ssh/id_ed25519";

  # Collect all source datasets across all jobs for ZFS permission grants
  allSourceDatasets = lib.concatMap (job: job.sourceDatasets) (lib.attrValues cfg.jobs);

  # Remap source dataset to target by replacing the source pool name with targetPool.
  # e.g. "zpool-xsvr1-main/systembackups" + targetPool="zpool-xsvr2"
  #   →  "zpool-xsvr2/systembackups"
  mkTargetDataset =
    dataset: targetPool:
    let
      parts = lib.splitString "/" dataset;
      suffix = lib.concatStringsSep "/" (lib.tail parts);
    in
    "${targetPool}/${suffix}";

  # Build the syncoid invocation for one dataset within a job
  mkSyncoidCommand =
    dataset: job:
    let
      targetDataset = mkTargetDataset dataset job.targetPool;
      target = "${job.targetUser}@${job.targetHost}";
    in
    ''
      echo "Replicating ${dataset} → ${job.targetHost}:${targetDataset}..."
      ${pkgs.sanoid}/bin/syncoid \
        --no-privilege-elevation \
        --sshkey ${sshKeyPath} \
        --recursive \
        ${dataset} \
        ${target}:${targetDataset}
    '';

  # Build a systemd service for one replication job
  mkReplicationService =
    jobName: job:
    lib.nameValuePair "zfs-replication-${jobName}" {
      description = "ZFS replication job '${jobName}' to ${job.targetHost}:${job.targetPool}";
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

        if [ ! -f ${sshKeyPath} ]; then
          echo "ERROR: SSH key not found at ${sshKeyPath}"
          exit 1
        fi

        echo "Testing SSH connection to ${job.targetUser}@${job.targetHost}..."
        ${pkgs.openssh}/bin/ssh -i ${sshKeyPath} \
          -o StrictHostKeyChecking=no \
          -o BatchMode=yes \
          ${job.targetUser}@${job.targetHost} \
          "echo 'SSH connection successful'" || {
          echo "ERROR: Cannot connect to ${job.targetUser}@${job.targetHost}"
          exit 1
        }

        ${lib.concatMapStringsSep "\n" (dataset: mkSyncoidCommand dataset job) job.sourceDatasets}

        echo "Job '${jobName}' completed successfully"
      '';
    };

  # Build a systemd timer for one replication job
  mkReplicationTimer =
    jobName: job:
    lib.nameValuePair "zfs-replication-${jobName}" {
      description = "Timer for ZFS replication job '${jobName}'";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = job.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

  isSource = cfg.enable && cfg.jobs != { };
  isTarget = cfg.enable && cfg.sshPublicKey != null;
in
{
  options.services.zfsReplication = {
    enable = lib.mkEnableOption "ZFS replication via Syncoid";

    jobs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            sourceDatasets = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Datasets to replicate. The source pool name is replaced by targetPool on the receiving end.";
              example = [
                "zpool-xsvr1-main/systembackups"
                "zpool-xsvr1-main/documents"
              ];
            };
            targetHost = lib.mkOption {
              type = lib.types.str;
              description = "SSH hostname or IP of the receiving host";
              example = "xsvr2.lan";
            };
            targetPool = lib.mkOption {
              type = lib.types.str;
              description = "ZFS pool on the receiving host to replicate datasets into";
              example = "zpool-xsvr2";
            };
            targetUser = lib.mkOption {
              type = lib.types.str;
              default = "syncoid";
              description = "SSH user on the receiving host";
            };
            interval = lib.mkOption {
              type = lib.types.str;
              default = "hourly";
              description = "systemd OnCalendar interval for this job";
              example = "daily";
            };
          };
        }
      );
      default = { };
      description = "Replication jobs. Each job produces an independent systemd service and timer.";
    };

    sshPublicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SSH public key to authorize on this host for incoming syncoid connections (target side)";
    };
  };

  config = lib.mkMerge [
    # Source host: syncoid user, SSH key setup, ZFS permissions, per-job services/timers
    (lib.mkIf isSource {
      users.users.syncoid = {
        isSystemUser = true;
        group = "syncoid";
        description = "ZFS replication user";
        home = "/var/lib/syncoid";
        createHome = true;
        shell = pkgs.bashInteractive;
      };

      users.groups.syncoid = { };

      # Static services + per-job services merged into one assignment
      systemd.services = {
        # Auto-generate SSH key for syncoid. Host configs using sops should
        # disable this service and provide syncoid-ssh-setup instead.
        syncoid-ssh-keygen = {
          description = "Generate SSH key for Syncoid";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "syncoid";
            Group = "syncoid";
            RemainAfterExit = true;
          };
          script = ''
            if [ ! -f ${sshKeyPath} ]; then
              mkdir -p $(dirname ${sshKeyPath})
              ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${sshKeyPath} -N "" -C "syncoid@$(hostname)"
              chmod 600 ${sshKeyPath}
              chmod 644 ${sshKeyPath}.pub
            fi
          '';
        };

        # Grant ZFS send/snapshot/hold on all source datasets across all jobs
        syncoid-zfs-permissions = {
          description = "Grant ZFS send permissions to Syncoid user";
          wantedBy = [ "multi-user.target" ];
          after = [ "zfs.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = lib.concatMapStringsSep "\n" (dataset: ''
            ${pkgs.zfs}/bin/zfs allow syncoid send,snapshot,hold ${dataset} || true
          '') allSourceDatasets;
        };
      } // lib.listToAttrs (lib.mapAttrsToList mkReplicationService cfg.jobs);

      # One systemd timer per job
      systemd.timers = lib.listToAttrs (lib.mapAttrsToList mkReplicationTimer cfg.jobs);

      environment.systemPackages = with pkgs; [
        sanoid
        zfs
      ];
    })

    # Target host: syncoid user authorized to receive replication
    (lib.mkIf isTarget {
      users.users.syncoid = {
        isSystemUser = true;
        group = "syncoid";
        description = "ZFS replication user";
        home = "/var/lib/syncoid";
        createHome = true;
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = [ cfg.sshPublicKey ];
      };

      users.groups.syncoid = { };

      # Grant receive permissions on all pools present on this host
      systemd.services.syncoid-target-zfs-permissions = {
        description = "Grant ZFS receive permissions to Syncoid user on target";
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          for pool in $(${pkgs.zfs}/bin/zpool list -H -o name); do
            ${pkgs.zfs}/bin/zfs allow syncoid \
              compression,create,destroy,mount,mountpoint,receive,rollback,snapshot,hold \
              "$pool" || true
          done
        '';
      };

      # Allow syncoid to create mountpoint directories under /zfs when receiving datasets
      systemd.tmpfiles.rules = [
        "d /zfs 2775 root syncoid -"
      ];

      environment.systemPackages = with pkgs; [
        sanoid
        zfs
        lzop
        mbuffer
      ];
    })
  ];
}

# Summary: NixOS module for BorgBackup client configuration with BorgWarehouse integration
{
  hostname,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;

  options.services.borgbackup-client = {
    enable = lib.mkEnableOption "BorgBackup client with BorgWarehouse";

    repository = lib.mkOption {
      type = lib.types.str;
      description = "BorgWarehouse repository SSH URL";
      example = "ssh://user@borgwarehouse.xrs444.net:2222/repos/hostname";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home"
        "/root"
        "/etc"
      ];
      description = "List of paths to backup";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "*.cache"
        "*/cache/*"
        "*/.cache/*"
        "*/Cache/*"
        "*/.local/share/Trash"
        "*/node_modules"
        "*/.nix-profile"
      ];
      description = "List of patterns to exclude from backup";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd timer schedule for automatic backups";
    };

    prune = {
      keep = lib.mkOption {
        type = lib.types.attrs;
        default = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
        description = "Retention policy for backups";
      };
    };
  };

  config = lib.mkIf config.services.borgbackup-client.enable {
    # Install borgbackup
    environment.systemPackages = [ pkgs.borgbackup ];

    # Configure borgbackup jobs
    services.borgbackup.jobs."${hostname}" = {
      repo = config.services.borgbackup-client.repository;
      paths = config.services.borgbackup-client.paths;
      exclude = config.services.borgbackup-client.exclude;

      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /run/secrets/borg-passphrase";
      };

      compression = "auto,zstd";
      startAt = config.services.borgbackup-client.schedule;

      prune.keep = config.services.borgbackup-client.prune.keep;

      preHook = ''
        echo "Starting backup for ${hostname} at $(date)"
      '';

      postHook = ''
        echo "Backup completed for ${hostname} at $(date)"
      '';
    };

    # Borg passphrase secret (requires sops configuration per-host)
    # Example per-host configuration:
    # sops.secrets."borg-passphrase" = {
    #   sopsFile = ../../../secrets/borg-${hostname}.yaml;
    #   key = "passphrase";
    # };
  };
}

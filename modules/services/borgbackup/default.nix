# Summary: NixOS BorgBackup client for BorgWarehouse, enabled via the "borg-client" hostRole; backs up /home with a per-host sops key + passphrase.
# Secrets live in secrets/borg-<hostname>.yaml (keys: passphrase, ssh_private_key,
# ssh_public_key). The repo name comes from ./repos.nix — until it is filled in for
# a host, only the secrets are deployed and no backup job exists.
{
  hostname,
  hostRoles ? [ ],
  lib,
  config,
  pkgs,
  ...
}:
let
  hasRole = lib.elem "borg-client" hostRoles;
  borg = import ./repos.nix;
  repoName = borg.repoNames.${hostname} or null;
  stateDir = "/var/lib/borg-client";
in
{
  options.services.borgbackup-client = {
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/home" ];
      description = "Paths to back up. /etc and /root are intentionally excluded: /etc is generated from the flake.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "*/.cache"
        "*/Cache"
        "*/.local/share/Trash"
        "*/node_modules"
        "*/.nix-profile"
      ];
      description = "Patterns to exclude from the backup.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd OnCalendar schedule for the backup job.";
    };

    prune.keep = lib.mkOption {
      type = lib.types.attrs;
      default = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      description = "Retention policy applied after each backup.";
    };
  };

  config = lib.mkIf hasRole (
    let
      cfg = config.services.borgbackup-client;
      sopsFile = ../../../secrets/borg-${hostname}.yaml;
    in
    {
      environment.systemPackages = [ pkgs.borgbackup ];

      sops.secrets."borg-passphrase" = {
        inherit sopsFile;
        key = "passphrase";
        mode = "0400";
      };
      sops.secrets."borg-ssh-key" = {
        inherit sopsFile;
        key = "ssh_private_key";
        mode = "0400";
      };

      systemd.tmpfiles.rules = [ "d ${stateDir} 0700 root root -" ];

      services.borgbackup.jobs.${hostname} = lib.mkIf (repoName != null) {
        repo = "ssh://${borg.user}@${borg.server}:${toString borg.port}/./${repoName}";
        inherit (cfg) paths exclude;
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.sops.secrets."borg-passphrase".path}";
        };
        environment.BORG_RSH = lib.concatStringsSep " " [
          "ssh"
          "-i ${config.sops.secrets."borg-ssh-key".path}"
          "-o IdentitiesOnly=yes"
          "-o StrictHostKeyChecking=accept-new"
          "-o UserKnownHostsFile=${stateDir}/known_hosts"
        ];
        compression = "auto,zstd";
        startAt = cfg.schedule;
        persistentTimer = true;
        prune.keep = cfg.prune.keep;
      };
    }
  );
}

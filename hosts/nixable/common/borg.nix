# Summary: Shared nixible tasks that set up the BorgWarehouse backup client on a Bazzite host (borg via Homebrew, sops-decrypted key/passphrase, systemd timer for /var/home).
#
# Usage in a host playbook:  ++ (import ../common/borg.nix { hostname = "xdt2-g"; })
#
# Secrets come from secrets/borg-<hostname>.yaml and are decrypted on the CONTROLLER
# (the machine running `nix run .#<host>`) with `sops`, so that machine needs `sops`
# on PATH and the user age key. Nothing secret is stored in the repo unencrypted.
#
# Two-phase: until the host's repo name is set in modules/services/borgbackup/repos.nix,
# only borg + the key/passphrase are deployed; the backup service/timer are added once
# the name is known.
{ hostname }:
let
  borg = import ../../../modules/services/borgbackup/repos.nix;
  repoName = borg.repoNames.${hostname} or null;
  secretsFile = ../../../secrets/borg-${hostname}.yaml;
  brew = "/home/linuxbrew/.linuxbrew/bin";
  stateDir = "/var/lib/borg-client";
  repoUrl = "ssh://${borg.user}@${borg.server}:${toString borg.port}/./${toString repoName}";

  # Bazzite is ostree-based: /home is a symlink to /var/home, so back up the real path.
  backupScript = ''
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${brew}:$PATH"
    export BORG_REPO='${repoUrl}'
    export BORG_PASSCOMMAND='cat ${stateDir}/passphrase'
    export BORG_RSH='ssh -i ${stateDir}/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=${stateDir}/known_hosts'

    # This host is the only client of its repo and the unit is a single-instance
    # oneshot, so any lock still present is stale (e.g. server OOM-killed mid-run).
    borg break-lock || true

    # First run: create the repo only if it really does not exist. Any other
    # failure (auth, network, lock) is surfaced instead of being masked by init.
    if ! info_out="$(borg info 2>&1)"; then
      if printf '%s' "$info_out" | grep -qi 'does not exist'; then
        borg init --encryption=repokey-blake2
      else
        printf '%s\n' "$info_out" >&2
        exit 1
      fi
    fi

    borg create --stats --compression auto,zstd \
      --exclude '*/.cache' --exclude '*/Cache' --exclude '*/.local/share/Trash' \
      --exclude '*/node_modules' --exclude '*/.local/share/Steam' \
      '::${hostname}-{now:%Y-%m-%dT%H:%M}' /var/home

    borg prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6
  '';
in
[
  {
    name = "Check whether borgbackup is installed via Homebrew";
    become = true;
    become_user = "thomas-local";
    command = "${brew}/brew list --versions borgbackup";
    register = "borg_brew";
    changed_when = false;
    failed_when = false;
  }
  {
    name = "Install borgbackup via Homebrew";
    become = true;
    become_user = "thomas-local";
    command = "${brew}/brew install borgbackup";
    when = "borg_brew.rc != 0";
  }
  {
    name = "Decrypt borg secrets on the controller";
    set_fact = {
      borg_secrets = "{{ lookup('pipe', 'sops -d --output-type json ${secretsFile}') | from_json }}";
    };
    no_log = true;
  }
  {
    name = "Create borg client state directory";
    file = {
      path = stateDir;
      state = "directory";
      owner = "root";
      group = "root";
      mode = "0700";
    };
  }
  {
    name = "Deploy borg passphrase";
    copy = {
      dest = "${stateDir}/passphrase";
      content = "{{ borg_secrets.passphrase }}";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    no_log = true;
  }
  {
    name = "Deploy borg SSH private key";
    copy = {
      dest = "${stateDir}/id_ed25519";
      content = "{{ borg_secrets.ssh_private_key }}";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    no_log = true;
  }
]
++ (
  if repoName == null then
    [
      {
        name = "Borg repo name not set yet — skipping backup service";
        debug.msg = "Set repoNames.${hostname} in modules/services/borgbackup/repos.nix, then re-run.";
      }
    ]
  else
    [
      {
        name = "Deploy borg backup script";
        copy = {
          dest = "${stateDir}/backup.sh";
          content = backupScript;
          owner = "root";
          group = "root";
          mode = "0700";
        };
      }
      {
        name = "Deploy borg-backup.service";
        copy = {
          dest = "/etc/systemd/system/borg-backup.service";
          mode = "0644";
          content = ''
            [Unit]
            Description=BorgBackup of /var/home to BorgWarehouse
            After=network-online.target
            Wants=network-online.target
            # Give up after 5 failed attempts in an hour rather than retrying forever.
            StartLimitIntervalSec=1h
            StartLimitBurst=5

            [Service]
            Type=oneshot
            # The machine may have only just woken (timer WakeSystem=true), so
            # the network can lag behind: retry a few times instead of failing.
            Restart=on-failure
            RestartSec=2min
            # Run via bash rather than exec'ing the script directly: SELinux on
            # Bazzite blocks executing var_lib_t files (203/EXEC).
            # systemd-inhibit stops the 15-min idle suspend killing a long backup.
            ExecStart=/usr/bin/systemd-inhibit --what=sleep:idle --mode=block --who=borg-backup --why="Backing up /var/home" /usr/bin/bash ${stateDir}/backup.sh
          '';
        };
        register = "borg_service";
      }
      {
        name = "Deploy borg-backup.timer";
        copy = {
          dest = "/etc/systemd/system/borg-backup.timer";
          mode = "0644";
          content = ''
            [Unit]
            Description=Daily BorgBackup

            [Timer]
            OnCalendar=daily
            RandomizedDelaySec=1h
            Persistent=true
            # Wake the machine from suspend (RTC alarm) to run the backup.
            # Does not help if it is fully powered off.
            WakeSystem=true

            [Install]
            WantedBy=timers.target
          '';
        };
        register = "borg_timer";
      }
      {
        name = "Enable borg-backup.timer";
        systemd = {
          name = "borg-backup.timer";
          enabled = true;
          # restarted (not started) so edits to the timer unit (e.g. WakeSystem) take effect.
          state = "restarted";
          daemon_reload = true;
        };
      }
    ]
)

# Nixible configuration for xfw (Firewalla Gold Pro — edge firewall/router,
# default gateway ".250" on every VLAN). Deploys the Scanopy scanning daemon
# as a Docker container, giving it the widest possible L2/L3 network view of
# any host in the fleet (no NixOS host or k8s node reaches more than two
# subnets — see the Scanopy deployment plan).
#
# Firewalla runs Debian Linux with an SSH-accessible "pi" user (confirmed via
# https://help.firewalla.com/hc/en-us/articles/115004397274, not guessed) —
# NOT DietPi/Bazzite. It's a managed security appliance, not a general-purpose
# Linux box: only touch the sanctioned customization points documented at
# https://help.firewalla.com/hc/en-us/articles/360048882174 (Docker under
# ~/.firewalla/run/docker/<name>/, boot hooks under
# ~/.firewalla/config/post_main.d/) — don't apt-get install packages Firewalla
# itself manages (docker, its own network stack), and don't assume the vendor
# firmware won't reset non-sanctioned changes on a major update.
#
# One-time bootstrap (SSH is off by default, and this must be done from the
# Firewalla app first — Settings > Advanced > Configurations > SSH Console >
# Reset Password): then from the nix repo root,
#   just deploy-ssh-key xfw pi
# creates the `ansible` user this playbook connects as (see hosts/nixable/common).
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};

  daemonComposeDir = "/home/pi/.firewalla/run/docker/scanopy-daemon";
  nfsMountPoint = "/mnt/scanopy-daemon";
in {
  collections = common.collections // {};

  inventory = {
    all = {
      hosts = {
        xfw = {
          # Mgmt VLAN (14) IP, per NetBox inventory (netbox-import/populate_netbox.py)
          # and xswcore's own default-route target — same address as the box's
          # ".250" gateway role on every other VLAN.
          ansible_host = "172.18.4.250";
          ansible_connection = "ssh";
        };
      };
      vars = common.vars;
    };
  };

  playbook = [
    {
      name = "Deploy Scanopy scanning daemon to xfw";
      hosts = "xfw";
      # Defensive, matching hosts/nixable/xdash1: don't assume python3 is
      # present on a non-Fedora target until proven — every Ansible module
      # but "raw" needs it for fact-gathering.
      gather_facts = false;
      become = true;

      tasks = [
        {
          name = "Bootstrap python3 (required for all other Ansible modules)";
          raw = "which python3 || (apt-get update && apt-get install -y python3)";
          changed_when = false;
        }
        {
          name = "Gather facts";
          setup = {};
        }
        {
          name = "Verify connectivity";
          ping = {};
        }
        {
          name = "Display host information";
          debug.msg = "Connected to {{ inventory_hostname }} ({{ ansible_distribution }} {{ ansible_distribution_version }})";
        }
        {
          # Docker itself is a Firewalla-managed feature (enable it via the
          # Firewalla app first if this fails) — deliberately NOT apt-installed
          # here, unlike a generic Debian package.
          name = "Verify Docker is available (enable via the Firewalla app if this fails)";
          "ansible.builtin.command" = "docker --version";
          changed_when = false;
        }
        {
          # nfs-common IS safe to apt-install — it's a generic client package,
          # not something Firewalla's own firmware manages.
          name = "Install nfs-common (NFS client support)";
          package = {
            name = "nfs-common";
            state = "present";
          };
        }
        {
          name = "Mount xsvr1 NFS export for daemon config persistence (identity/API key)";
          "ansible.posix.mount" = {
            src = "172.20.3.201:/export/zfs/system/scanopy";
            path = nfsMountPoint;
            fstype = "nfs";
            opts = "vers=4.1,hard,intr";
            state = "mounted";
          };
        }
        {
          name = "Create Scanopy daemon compose directory (Firewalla's sanctioned Docker location)";
          "ansible.builtin.file" = {
            path = daemonComposeDir;
            state = "directory";
            owner = "pi";
            group = "pi";
            mode = "0755";
          };
        }
        {
          # scanopy_daemon_api_key is intentionally NOT defaulted — it's
          # minted once in the Scanopy UI (Discover > Daemons) after the
          # server is live, and Jinja will fail loudly on an undefined
          # variable rather than silently deploying an empty/placeholder
          # key. Pass it explicitly: nix run .#xfw -- --extra-vars
          # scanopy_daemon_api_key=<key-from-ui>
          name = "Deploy docker-compose.yml for the Scanopy daemon";
          "ansible.builtin.copy" = {
            dest = "${daemonComposeDir}/docker-compose.yml";
            owner = "pi";
            group = "pi";
            mode = "0644";
            content = ''
              name: scanopy-daemon
              services:
                daemon:
                  # TODO: pin to a real released tag before deploying — see
                  # https://github.com/scanopy/scanopy/releases (never :latest).
                  image: ghcr.io/scanopy/scanopy/daemon:latest
                  container_name: scanopy-daemon
                  network_mode: host
                  privileged: true
                  restart: unless-stopped
                  environment:
                    SCANOPY_LOG_LEVEL: info
                    SCANOPY_SERVER_URL: https://scanopy.xrs444.net
                    SCANOPY_NAME: xfw
                    SCANOPY_MODE: daemon_poll
                    SCANOPY_DAEMON_API_KEY: "{{ scanopy_daemon_api_key }}"
                  volumes:
                    - ${nfsMountPoint}:/root/.config/scanopy/daemon
            '';
          };
        }
        {
          # Firewalla's own boot process doesn't guarantee arbitrary systemd
          # units/containers restart on power-cycle — post_main.d is the
          # documented, sanctioned boot hook (Firewalla Tutorial: Expanding
          # With Docker Containers). Idempotent: `docker compose up -d`
          # no-ops if already running, matching restart:unless-stopped.
          name = "Deploy boot-persistence hook (Firewalla's post_main.d convention)";
          "ansible.builtin.copy" = {
            dest = "/home/pi/.firewalla/config/post_main.d/start_scanopy.sh";
            owner = "pi";
            group = "pi";
            mode = "0755";
            content = ''
              #!/bin/bash
              # Deployed by nix/hosts/nixable/xfw/default.nix — starts the Scanopy
              # scanning daemon on every Firewalla boot. Safe to re-run.
              set -e
              sudo systemctl start docker
              cd ${daemonComposeDir}
              docker compose up -d
            '';
          };
        }
        {
          name = "Start the Scanopy daemon now (don't wait for a reboot)";
          "ansible.builtin.command" = {
            cmd = "docker compose up -d";
            chdir = daemonComposeDir;
          };
          changed_when = true;
        }
      ];
    }
  ];
}

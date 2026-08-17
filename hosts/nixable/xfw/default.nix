# Nixible configuration for xfw (Firewalla Gold Pro — edge firewall/router,
# default gateway ".250" on every VLAN). Deploys two Docker containers:
# - Scanopy scanning daemon, giving it the widest possible L2/L3 network view
#   of any host in the fleet (no NixOS host or k8s node reaches more than two
#   subnets — see the Scanopy deployment plan).
# - node_exporter, for xfw's own host OS metrics (CPU/mem/disk/net). This is
#   distinct from flux/apps/observability/monitoring/firewalla-exporter/,
#   which polls Firewalla's MSP *cloud* API for box/device/alarm telemetry
#   and runs as an ordinary k8s Deployment (no flash-wear concern there —
#   only containers running ON this box need the stateless treatment below).
#
# Firewalla runs Ubuntu 22.04 with an SSH-accessible "pi" user (confirmed live
# — the vendor's own docs said "Debian Linux", which was imprecise/wrong).
# NOT DietPi/Bazzite. It's a managed security appliance, not a general-purpose
# Linux box: only touch the sanctioned customization points documented at
# https://help.firewalla.com/hc/en-us/articles/360048882174 (Docker under
# ~/.firewalla/run/docker/<name>/, boot hooks under
# ~/.firewalla/config/post_main.d/) — don't apt-get install packages Firewalla
# itself manages (docker, its own network stack), and don't assume the vendor
# firmware won't reset non-sanctioned changes on a major update.
#
# Confirmed live: apt is locked to Firewalla's own minimal package mirror, not
# full Ubuntu main/universe — `nfs-common` (and presumably most generic
# packages) is NOT installable. So daemon config persistence is a purely
# LOCAL directory under the sanctioned Docker path, not NFS-backed from
# xsvr1 as originally planned (nix/hosts/nixos/xsvr1/shares.nix still has
# the now-unused /export/zfs/system/scanopy export — harmless to leave, low
# priority cleanup). Acceptable: it's just the daemon's identity/API key, not
# real data — a Firewalla reflash means re-enrolling the daemon either way.
#
# One-time bootstrap (SSH is off by default, and this must be done from the
# Firewalla app first — Settings > Advanced > Configurations > SSH Console >
# Reset Password): then from the nix repo root,
#   just deploy-ssh-key xfw pi
# creates the `ansible` user this playbook connects as (see hosts/nixable/common).
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};

  daemonComposeDir = "/home/pi/.firewalla/run/docker/scanopy-daemon";
  daemonConfigDir = "${daemonComposeDir}/config";
  # node_exporter is fully stateless -- no config dir needed, unlike Scanopy.
  nodeExporterComposeDir = "/home/pi/.firewalla/run/docker/node-exporter";
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
          tags = ["always"];
        }
        {
          name = "Gather facts";
          setup = {};
          tags = ["always"];
        }
        {
          name = "Verify connectivity";
          ping = {};
          tags = ["always"];
        }
        {
          name = "Display host information";
          debug.msg = "Connected to {{ inventory_hostname }} ({{ ansible_distribution }} {{ ansible_distribution_version }})";
          tags = ["always"];
        }
        {
          # Docker itself is a Firewalla-managed feature (enable it via the
          # Firewalla app first if this fails) — deliberately NOT apt-installed
          # here, unlike a generic Debian package.
          name = "Verify Docker is available (enable via the Firewalla app if this fails)";
          "ansible.builtin.command" = "docker --version";
          changed_when = false;
          tags = ["always"];
        }
        {
          name = "Create Scanopy daemon compose + config directories (Firewalla's sanctioned Docker location)";
          "ansible.builtin.file" = {
            path = "{{ item }}";
            state = "directory";
            owner = "pi";
            group = "pi";
            mode = "0755";
          };
          loop = [
            daemonComposeDir
            daemonConfigDir
          ];
          tags = ["scanopy"];
        }
        {
          # scanopy_daemon_api_key is intentionally NOT defaulted — it's
          # minted once in the Scanopy UI (Discover > Daemons) after the
          # server is live, and Jinja will fail loudly on an undefined
          # variable rather than silently deploying an empty/placeholder
          # key. Pass it explicitly: nix run .#xfw -- --extra-vars
          # scanopy_daemon_api_key=<key-from-ui>
          # While Scanopy is being rebuilt (corrupted storage, separate
          # session) and no key exists yet, deploy everything else with
          # `nix run .#xfw -- --tags node-exporter` to skip this task and
          # the rest of the scanopy-tagged ones without failing the play.
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
                  # Pinned to match the server version deployed in flux
                  # (apps/services/scanopy) — bump both together.
                  image: ghcr.io/scanopy/scanopy/daemon:v0.17.9
                  container_name: scanopy-daemon
                  # host networking is required: the daemon must see every
                  # bond0.<vlan> interface to scan those segments.
                  network_mode: host
                  # Upstream's compose uses privileged:true, but scanning
                  # only needs raw sockets + interface access. If discovery
                  # breaks after a bump, revert to privileged:true.
                  cap_add:
                    - NET_RAW
                    - NET_ADMIN
                  restart: unless-stopped
                  environment:
                    SCANOPY_LOG_LEVEL: info
                    SCANOPY_SERVER_URL: https://scanopy.xrs444.net
                    SCANOPY_NAME: xfw
                    SCANOPY_MODE: daemon_poll
                    SCANOPY_DAEMON_API_KEY: "{{ scanopy_daemon_api_key }}"
                    # Confirmed live via `ip -br addr` on xfw: eth1 is the WAN
                    # interface (public IP) — scanning it means
                    # probing the public internet, not the LAN. eth0/eth3 are
                    # just the raw bond0 members (redundant with bond0 itself,
                    # which carries no untagged traffic — every internal VLAN
                    # is a bond0.<id> sub-interface). Excluded too: vpn_* (VPN
                    # tunnels, not LAN inventory), ifb*/lo/wg0/docker0 (not
                    # real network segments). Update this list if VLANs are
                    # added/removed on xfw (see nix/hosts/nixable/xswcore for
                    # the switch-side VLAN definitions this must stay in sync
                    # with).
                    SCANOPY_INTERFACES: bond0.10,bond0.14,bond0.15,bond0.16,bond0.17,bond0.19,bond0.20,bond0.21,bond0.22,bond0.100,bond0.111,bond0.112,bond0.114,bond0.115,bond0.1000,bond0.1001,bond0.2000,bond0.2001,bond0.2002,bond0.2004
                  volumes:
                    - ${daemonConfigDir}:/root/.config/scanopy/daemon
                  # Confirmed live: the Firewalla's own host-level DNS
                  # resolution bypasses its local dnsmasq entirely and
                  # queries upstream (1.1.1.1) directly, which only has the
                  # PUBLIC xrs444.net zone — no "scanopy" record there (that
                  # only exists in the internal dnsmasq LAN clients use).
                  # Pin the hostname to the known Traefik ingress IP instead
                  # (same one vikunja/netbox/etc. resolve to internally).
                  # TLS still validates fine: SNI/cert matching is based on
                  # the hostname string, not the resolved IP, and the
                  # wildcard cert covers *.xrs444.net.
                  extra_hosts:
                    - "scanopy.xrs444.net:172.21.0.2"
            '';
          };
          tags = ["scanopy"];
        }
        {
          name = "Create node_exporter compose directory (Firewalla's sanctioned Docker location)";
          "ansible.builtin.file" = {
            path = nodeExporterComposeDir;
            state = "directory";
            owner = "pi";
            group = "pi";
            mode = "0755";
          };
          tags = ["node-exporter"];
        }
        {
          # Host OS metrics for xfw itself (CPU/mem/disk/net of the Firewalla
          # appliance) -- separate from firewalla-exporter in flux (box/device/
          # alarm telemetry via the MSP cloud API, no flash-wear concern since
          # that one's an ordinary k8s Deployment). This one genuinely runs on
          # the box, so it gets the same flash-wear treatment as Scanopy:
          # logging disabled, no persistent volume/writable bind mount.
          # /proc, /sys, / are mounted read-only (required for node_exporter to
          # report real host stats instead of the container's own view) --
          # read-only mounts don't wear flash, only writes do.
          name = "Deploy docker-compose.yml for node_exporter";
          "ansible.builtin.copy" = {
            dest = "${nodeExporterComposeDir}/docker-compose.yml";
            owner = "pi";
            group = "pi";
            mode = "0644";
            content = ''
              name: node-exporter
              services:
                node-exporter:
                  image: quay.io/prometheus/node-exporter:v1.8.2
                  container_name: node-exporter
                  network_mode: host
                  pid: host
                  restart: unless-stopped
                  logging:
                    driver: none
                  command:
                    - --path.procfs=/host/proc
                    - --path.sysfs=/host/sys
                    - --path.rootfs=/host/root
                    - --collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+)($$|/)
                  volumes:
                    - /proc:/host/proc:ro
                    - /sys:/host/sys:ro
                    - /:/host/root:ro
            '';
          };
          tags = ["node-exporter"];
        }
        {
          # post_main.d does not exist by default — must be created first
          # (confirmed live), matching the vendor tutorial's own `mkdir` step.
          name = "Ensure Firewalla's post_main.d boot-hook directory exists";
          "ansible.builtin.file" = {
            path = "/home/pi/.firewalla/config/post_main.d";
            state = "directory";
            owner = "pi";
            group = "pi";
            mode = "0755";
          };
          tags = ["always"];
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
          tags = ["scanopy"];
        }
        {
          name = "Deploy boot-persistence hook for node_exporter (Firewalla's post_main.d convention)";
          "ansible.builtin.copy" = {
            dest = "/home/pi/.firewalla/config/post_main.d/start_node_exporter.sh";
            owner = "pi";
            group = "pi";
            mode = "0755";
            content = ''
              #!/bin/bash
              # Deployed by nix/hosts/nixable/xfw/default.nix — starts node_exporter
              # on every Firewalla boot. Safe to re-run.
              set -e
              sudo systemctl start docker
              cd ${nodeExporterComposeDir}
              docker compose up -d
            '';
          };
          tags = ["node-exporter"];
        }
        {
          # Docker isn't always running by default on Firewalla (confirmed
          # live: "Cannot connect to the Docker daemon" even though the CLI
          # is present) — the vendor's own post_main.d boot script explicitly
          # starts it too, so this isn't a one-off state.
          name = "Ensure Docker service is running";
          "ansible.builtin.systemd" = {
            name = "docker";
            state = "started";
          };
          tags = ["always"];
        }
        {
          name = "Start the Scanopy daemon now (don't wait for a reboot)";
          "ansible.builtin.command" = {
            cmd = "docker compose up -d";
            chdir = daemonComposeDir;
          };
          changed_when = true;
          tags = ["scanopy"];
        }
        {
          name = "Start node_exporter now (don't wait for a reboot)";
          "ansible.builtin.command" = {
            cmd = "docker compose up -d";
            chdir = nodeExporterComposeDir;
          };
          changed_when = true;
          tags = ["node-exporter"];
        }
      ];
    }
  ];
}

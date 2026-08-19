# Nixible configuration for xfw (Firewalla Gold Pro — edge firewall/router,
# default gateway ".250" on every VLAN). Deploys four Docker containers:
# - Scanopy scanning daemon, giving it the widest possible L2/L3 network view
#   of any host in the fleet (no NixOS host or k8s node reaches more than two
#   subnets — see the Scanopy deployment plan).
# - node_exporter, for xfw's own host OS metrics (CPU/mem/disk/net). This is
#   distinct from flux/apps/observability/monitoring/firewalla-exporter/,
#   which polls Firewalla's MSP *cloud* API for box/device/alarm telemetry
#   and runs as an ordinary k8s Deployment (no flash-wear concern there —
#   only containers running ON this box need the stateless treatment below).
# - Tailscale, replacing the xts1/xts2 SBC pair as subnet router + exit node.
#   Running it on xfw (the actual gateway/NAT box) rather than a downstream
#   SBC eliminates the exit-node + subnet-router-without-SNAT conflict and
#   the 172.16.0.0/12 table-52 policy-routing hazard those SBCs hit — see
#   nix/modules/services/tailscale/default.nix's inline history for that
#   design and cerebrum 341-358. xfw already does LAN routing/NAT/forwarding
#   for the whole network, so nothing extra is needed for kernel forwarding
#   (unlike a plain container host) and there's no BGP/keepalived HA
#   apparatus to run — the gateway's availability already gates the network.
# - dns-forwarder, a small dnsmasq instance bound specifically to tailscale0.
#   Needed because Firewalla runs one dnsmasq PER VLAN (confirmed live via
#   `ps aux`), each with `interface=bond0.X` + `bind-interfaces` -- so none of
#   them answer queries arriving via the tunnel (tailscale0), even though the
#   destination IP (e.g. 172.18.10.250) is reachable and pings fine -- the
#   query never reaches a bound listener, which looks like a timeout to the
#   client (confirmed live 2026-08-19 via `dig`/`conntrack`/`ss -ulnp`).
#   Firewalla's own native VPN server hits the identical problem and solves
#   it the same way: a resolver bound to its own tunnel interface, pushing a
#   VPN-subnet address (10.200.221.1) to its clients rather than reusing the
#   per-VLAN instances. This mirrors that pattern for the tailnet: binds only
#   to tailscale0, forwards `lan`/`xrs444.net` to Firewalla's real resolver
#   (172.18.10.250 -- safe/fast since THIS query is locally-originated from
#   xfw itself, not forwarded/NAT'd through, so it doesn't hit the same
#   interface-binding wall), and forwards everything else to public
#   resolvers directly. Point the Tailscale admin console's DNS settings
#   (lan Split DNS, xrs444.net Split DNS, and Global Nameservers) at xfw's
#   own tailscale IP instead of 172.18.10.250 once this is deployed.
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
  tailscaleComposeDir = "/home/pi/.firewalla/run/docker/tailscale";
  # tailscaled's own state (identity/keys/netmap) -- low-write, like Scanopy's
  # config dir, not chatty like a log. Must persist across container recreate
  # or every redeploy re-triggers a fresh device enrollment.
  tailscaleStateDir = "${tailscaleComposeDir}/state";
  # dns-forwarder is fully stateless (just a forwarding policy) -- no
  # persistent dir needed, same as node_exporter.
  dnsForwarderComposeDir = "/home/pi/.firewalla/run/docker/dns-forwarder";
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
          name = "Create Tailscale compose + state directories (Firewalla's sanctioned Docker location)";
          "ansible.builtin.file" = {
            path = "{{ item }}";
            state = "directory";
            owner = "pi";
            group = "pi";
            mode = "0755";
          };
          loop = [
            tailscaleComposeDir
            tailscaleStateDir
          ];
          tags = ["tailscale"];
        }
        {
          # Kernel-mode networking (TS_USERSPACE=false) + network_mode: host +
          # /dev/net/tun gives real subnet-router/exit-node throughput, matching
          # the bare-host NixOS setup this replaces -- not the slower userspace
          # fallback. network_mode: host means Docker's own `sysctls:` key can't
          # be used here (rejected: "network sysctls are not allowed with host
          # network mode") -- that's fine, xfw is the LAN gateway and already has
          # IPv4/IPv6 forwarding enabled to route the whole network, so no extra
          # sysctl work is needed here (unlike a non-gateway container host).
          # Flags mostly mirror nix/modules/services/tailscale/default.nix's
          # exit-node role (same advertised routes, --accept-dns=false since
          # xfw runs its own dnsmasq) minus the BGP/keepalived HA machinery,
          # which existed only to make a *non-gateway* subnet router highly
          # available -- unnecessary here since the gateway's own availability
          # already gates the network.
          #
          # Deliberately NOT --snat-subnet-routes=false, unlike xts1/xts2:
          # that flag was carried over from the SBC design without
          # re-examining it for this host and caused real subnet-routed
          # traffic to be unreachable (verified live 2026-08-19). Firewalla's
          # own FR_FORWARD/FW_FORWARD ACL chains key off which of its
          # configured networks/VLANs traffic belongs to; un-SNAT'd packets
          # arriving from 100.64.0.0/10 don't match any of them. SNAT (the
          # default) rewrites forwarded packets to xfw's own address before
          # they hit the LAN, which Firewalla implicitly trusts as its own
          # router traffic -- matching the community reference script
          # (mbierman/firewalla-tailscale-docker), which achieves the same
          # thing via a manual `iptables -t nat -A POSTROUTING -s
          # 100.64.0.0/10 -j MASQUERADE` rule; omitting the flag here lets
          # tailscaled manage the equivalent NAT itself instead. Trade-off:
          # Firewalla's flow logs/future per-device ACLs see xfw as the
          # traffic source, not the real Tailscale client IP.
          name = "Deploy docker-compose.yml for Tailscale";
          "ansible.builtin.copy" = {
            dest = "${tailscaleComposeDir}/docker-compose.yml";
            owner = "pi";
            group = "pi";
            mode = "0644";
            content = ''
              name: tailscale
              services:
                tailscale:
                  image: tailscale/tailscale:v1.102.2
                  container_name: tailscale
                  hostname: xfw
                  network_mode: host
                  restart: unless-stopped
                  logging:
                    driver: json-file
                    options:
                      max-size: "5m"
                      max-file: "3"
                  cap_add:
                    - NET_ADMIN
                    - NET_RAW
                  devices:
                    - /dev/net/tun:/dev/net/tun
                  environment:
                    TS_HOSTNAME: xfw
                    TS_STATE_DIR: /var/lib/tailscale
                    TS_USERSPACE: "false"
                    TS_ACCEPT_DNS: "false"
                    # Only consumed on first bring-up (Tailscale ignores it once
                    # the state dir already holds an authenticated identity), so
                    # default to empty -- unlike Scanopy's API key, re-running
                    # this tag later shouldn't require re-supplying a live key.
                    # First run: nix run .#xfw -- --tags tailscale --extra-vars
                    # tailscale_authkey=<key-from-admin-console>
                    TS_AUTHKEY: '{{ tailscale_authkey | default("") }}'
                    # --reset: `tailscale up` otherwise refuses to apply a
                    # flag change that drops a previously-set non-default
                    # flag (e.g. removing --snat-subnet-routes=false) unless
                    # every non-default flag is restated -- without --reset
                    # it errors out on every container start once prefs
                    # differ from TS_EXTRA_ARGS, crash-looping forever
                    # (confirmed live 2026-08-19: "requires mentioning all
                    # non-default flags"). --reset makes each start
                    # authoritative: TS_EXTRA_ARGS always fully replaces
                    # whatever was previously set, matching how this file is
                    # meant to be used (declarative, not incremental).
                    TS_EXTRA_ARGS: >-
                      --reset
                      --advertise-exit-node
                      --advertise-routes=172.16.0.0/12,2600:8800:218d:9a00::/56
                      --accept-dns=false
                  volumes:
                    - ${tailscaleStateDir}:/var/lib/tailscale
            '';
          };
          tags = ["tailscale"];
        }
        {
          name = "Create dns-forwarder compose directory (Firewalla's sanctioned Docker location)";
          "ansible.builtin.file" = {
            path = dnsForwarderComposeDir;
            state = "directory";
            owner = "pi";
            group = "pi";
            mode = "0755";
          };
          tags = ["dns-forwarder"];
        }
        {
          # Binds only to tailscale0 (network_mode: host, same as the
          # tailscale container -- shares the host netns so tailscale0 is
          # directly visible here even though a different container created
          # it). `lan`/`xrs444.net` forward to Firewalla's real per-VLAN
          # resolver (172.18.10.250) -- this query is locally-originated
          # from xfw itself, so it doesn't hit the interface-binding wall
          # that blocks tunnel-forwarded queries to the same address.
          # Everything else forwards straight to public resolvers, replacing
          # 172.18.10.250's role as Global Nameserver for the tailnet too,
          # since that's equally unreachable from tunnel clients.
          name = "Deploy docker-compose.yml for dns-forwarder";
          "ansible.builtin.copy" = {
            dest = "${dnsForwarderComposeDir}/docker-compose.yml";
            owner = "pi";
            group = "pi";
            mode = "0644";
            content = ''
              name: dns-forwarder
              services:
                dns-forwarder:
                  image: 4km3/dnsmasq:2.90-r3
                  container_name: dns-forwarder
                  network_mode: host
                  restart: unless-stopped
                  cap_add:
                    - NET_ADMIN
                  logging:
                    driver: json-file
                    options:
                      max-size: "5m"
                      max-file: "3"
                  command:
                    - -k
                    - --interface=tailscale0
                    - --bind-interfaces
                    - --no-resolv
                    - --no-hosts
                    - --log-facility=-
                    - --server=/lan/172.18.10.250
                    - --server=/xrs444.net/172.18.10.250
                    - --server=1.1.1.1
                    - --server=8.8.8.8
            '';
          };
          tags = ["dns-forwarder"];
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
          name = "Deploy boot-persistence hook for Tailscale (Firewalla's post_main.d convention)";
          "ansible.builtin.copy" = {
            dest = "/home/pi/.firewalla/config/post_main.d/start_tailscale.sh";
            owner = "pi";
            group = "pi";
            mode = "0755";
            content = ''
              #!/bin/bash
              # Deployed by nix/hosts/nixable/xfw/default.nix — starts Tailscale
              # (subnet router + exit node) on every Firewalla boot. Safe to re-run.
              set -e
              sudo systemctl start docker
              cd ${tailscaleComposeDir}
              docker compose up -d
            '';
          };
          tags = ["tailscale"];
        }
        {
          # Named to sort after start_tailscale.sh (post_main.d scripts run in
          # glob order) so tailscale0 likely already exists when this starts --
          # not guaranteed, but harmless either way since restart:unless-stopped
          # self-heals: if dnsmasq fails to bind on first try, Docker just
          # restarts it until tailscale0 shows up.
          name = "Deploy boot-persistence hook for dns-forwarder (Firewalla's post_main.d convention)";
          "ansible.builtin.copy" = {
            dest = "/home/pi/.firewalla/config/post_main.d/start_tailscale_z_dns_forwarder.sh";
            owner = "pi";
            group = "pi";
            mode = "0755";
            content = ''
              #!/bin/bash
              # Deployed by nix/hosts/nixable/xfw/default.nix — starts the
              # tailscale0 DNS forwarder on every Firewalla boot. Safe to re-run.
              set -e
              sudo systemctl start docker
              cd ${dnsForwarderComposeDir}
              docker compose up -d
            '';
          };
          tags = ["dns-forwarder"];
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
        {
          name = "Start Tailscale now (don't wait for a reboot)";
          "ansible.builtin.command" = {
            cmd = "docker compose up -d";
            chdir = tailscaleComposeDir;
          };
          changed_when = true;
          tags = ["tailscale"];
        }
        {
          name = "Start dns-forwarder now (don't wait for a reboot)";
          "ansible.builtin.command" = {
            cmd = "docker compose up -d";
            chdir = dnsForwarderComposeDir;
          };
          changed_when = true;
          tags = ["dns-forwarder"];
        }
      ];
    }
  ];
}

# Summary: Unified Tailscale VPN module supporting client, server, and exit node configurations.
{
  hostname,
  hostRoles ? [ ],
  isWorkstation ? false,
  lib,
  pkgs,
  username,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Role-based configuration - roles come from flake.nix host definitions
  isPackageOnly = lib.elem "tailscale-package" hostRoles;
  isClient = lib.elem "tailscale-client" hostRoles;
  isExitNode = lib.elem "tailscale-exit-node" hostRoles;

  enableTailscale = isPackageOnly || isClient || isExitNode;
in
{
  config = lib.mkMerge [
    # Package-only configuration (for hosts that need tailscale CLI but manage service externally)
    (lib.mkIf (enableTailscale && isPackageOnly) {
      environment.systemPackages = with pkgs; [ tailscale ];
    })

    # Standard client configuration
    (lib.mkIf (enableTailscale && isClient) {
      services.tailscale = lib.mkMerge [
        { enable = true; }
        # Only on NixOS hosts (Darwin doesn't support these options)
        (lib.mkIf (!isDarwin) {
          extraUpFlags = [
            "--operator=${username}"
            "--accept-routes"
          ];
          extraSetFlags = [
            "--operator=${username}"
            "--accept-routes"
          ];
        })
      ];

      environment.systemPackages =
        with pkgs;
        [
          tailscale
        ]
        ++ lib.optionals isWorkstation [ trayscale ];
    })

    # Exit node configuration (NixOS only)
    (lib.mkIf (enableTailscale && isExitNode) {
      environment.systemPackages = with pkgs; [
        tailscale
        ethtool
        networkd-dispatcher
        keepalived
        bird2
      ];

      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--advertise-exit-node"
          # Do NOT add --accept-routes: both xts1 and xts2 advertise 172.16.0.0/12, so
          # accepting routes from each other installs that subnet in table 52, causing
          # responses to any 172.16.0.0/12 address (including LAN peers) to be routed
          # via tailscale0 instead of eth0 — breaking all local SSH/DNS/VRRP.
          "--advertise-routes=172.16.0.0/12,2600:8800:218d:9a00::/56"
          "--snat-subnet-routes=false"
          "--operator=${username}"
          # Exit nodes manage DNS via dnsmasq — don't let Tailscale overwrite resolv.conf.
          "--accept-dns=false"
        ];
        # Connect tailscaled to BIRD via unix socket so Tailscale can dynamically
        # inject/withdraw the 100.64.0.0/10 route when this node is the active router.
        # See https://tailscale.com/kb/1298/subnet-bgp
        extraDaemonFlags = [ "--bird-socket=/run/bird/bird.ctl" ];
        openFirewall = true;
        useRoutingFeatures = "both";
      };

      networking.firewall = {
        checkReversePath = "loose";
        allowedTCPPorts = [ 179 ]; # BGP port
      };

      services.networkd-dispatcher = {
        enable = true;
        rules."99-tailscale" = {
          onState = [ "routable" ];
          script = ''
            #!/bin/sh
            NIC=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')
            ethtool -K "$NIC" rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };

      # Bird BGP configuration per Tailscale's documented HA design:
      # https://tailscale.com/kb/1298/subnet-bgp
      # tailscaled (via --bird-socket) dynamically activates/deactivates the
      # "tailscale" static protocol, injecting 100.64.0.0/10 when this node is
      # the active subnet router. keepalived watches for this route to decide VIP.
      services.bird = {
        enable = true;
        config = lib.mkMerge [
          (lib.mkIf (hostname == "xts1") ''
            log syslog all;
            router id 172.18.10.1;

            # tailscaled injects/withdraws this route via --bird-socket
            protocol static tailscale {
              ipv4;
              route 100.64.0.0/10 via "tailscale0";
            }

            protocol device {
              scan time 10;
            }

            # iBGP with xts2: synchronises route state and provides peer detection
            protocol bgp xts2 {
              local 172.18.10.1 as 65002;
              neighbor 172.18.10.2 as 65002;

              ipv4 {
                import all;
                export all;
              };

              hold time 90;
              keepalive time 30;
            }

            # Install BIRD routes (including 100.64.0.0/10) into the kernel table
            protocol kernel {
              ipv4 {
                export all;
              };
            }
          '')
          (lib.mkIf (hostname == "xts2") ''
            log syslog all;
            router id 172.18.10.2;

            # tailscaled injects/withdraws this route via --bird-socket
            protocol static tailscale {
              ipv4;
              route 100.64.0.0/10 via "tailscale0";
            }

            protocol device {
              scan time 10;
            }

            # iBGP with xts1: synchronises route state and provides peer detection
            protocol bgp xts1 {
              local 172.18.10.2 as 65002;
              neighbor 172.18.10.1 as 65002;

              ipv4 {
                import all;
                export all;
              };

              hold time 90;
              keepalive time 30;
            }

            # Install BIRD routes (including 100.64.0.0/10) into the kernel table
            protocol kernel {
              ipv4 {
                export all;
              };
            }
          '')
        ];
      };

      # Keepalived health check: verify tailscaled has injected the Tailscale
      # CGNAT route (100.64.0.0/10) into the kernel routing table via BIRD.
      # tailscaled only does this when active as a subnet router; the route
      # appears with "proto bird" (installed by BIRD's kernel protocol export).
      # Using `ip route` avoids birdc version compatibility issues (running bird3
      # but pkgs.bird2 birdc can't connect to bird3's socket).
      environment.etc."check-bgp-session.sh" = {
        text = ''
          #!/bin/sh
          ${pkgs.iproute2}/bin/ip route show 100.64.0.0/10 2>/dev/null \
            | grep -q 'proto bird'
          exit $?
        '';
        mode = "0755";
      };

      # Bird exporter for Prometheus monitoring
      services.prometheus.exporters.bird = {
        enable = true;
        port = 9324;
        listenAddress = "0.0.0.0";
        openFirewall = true;
      };

      # Keepalived with BGP health monitoring
      services.keepalived = {
        enable = true;
        vrrpScripts = {
          check_bgp = {
            script = "/etc/check-bgp-session.sh";
            interval = 5; # Check every 5 seconds
            weight = -50; # Reduce priority by 50 if BGP fails
            fall = 2; # Require 2 failures before marking down
            rise = 2; # Require 2 successes before marking up
          };
        };
        vrrpInstances = {
          ts-vip = {
            # xts1 = RPi4 (end0), xts2 = Sweet Potato (eth0, confirm on first boot)
            interface = if hostname == "xts1" then "end0" else "eth0";
            virtualRouterId = 51;
            priority =
              if hostname == "xts1" then
                101
              else if hostname == "xts2" then
                100
              else
                99;
            state = if hostname == "xts1" then "MASTER" else "BACKUP";
            virtualIps = [
              { addr = "172.18.10.100/24"; }
              { addr = "2600:8800:218d:9a16::100/64"; }
            ];
            extraConfig = ''
              version 3
              # use_vmac removed: keepalived sets arp_filter=1 on the parent interface
              # when a macvlan is created. Combined with Tailscale's policy routing table 52
              # (which routes 172.16.0.0/12 via tailscale0), arp_filter causes the kernel to
              # silently drop ARP replies on eth0/end0 — the Firewalla can't ARP-resolve the
              # host and returns Destination Host Unreachable for all inbound traffic.
              authentication {
                auth_type PASS
                auth_pass tsexit
              }
              track_script {
                check_bgp
              }
              # Restart bird when becoming MASTER to ensure clean state
              notify_master "/run/current-system/systemd/bin/systemctl restart bird"
            '';
          };
        };
      };

      # Allow SSH, DNS, and monitoring via Tailscale IP on both nodes
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        22   # SSH via Tailscale
        53   # DNS via Tailscale (dnsmasq forwards .ts.net)
        9324 # bird_exporter
      ];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [
        53 # DNS via Tailscale
      ];

      # Allow VRRP multicast for keepalived
      networking.firewall.extraCommands = ''
        # Allow VRRP multicast
        iptables -A INPUT -d 224.0.0.18/32 -j ACCEPT
        iptables -A OUTPUT -d 224.0.0.18/32 -j ACCEPT
      '';
    })
  ];
}

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
          "--accept-routes"
          "--advertise-routes=172.16.0.0/12"
          "--snat-subnet-routes=false"
          "--operator=${username}"
        ];
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

      # Bird BGP configuration for Tailscale exit node redundancy with direct protocol
      services.bird = {
        enable = true;
        config = lib.mkMerge [
          (lib.mkIf (hostname == "xts1") ''
            log syslog all;
            router id 172.18.10.1;

            # Tailscale integration via direct protocol
            protocol direct {
              ipv4;
              interface "tailscale*";
            }

            # Device protocol for interface tracking
            protocol device {
              scan time 10;
            }

            # BGP protocol for peering with xts2
            protocol bgp xts2 {
              local 172.18.10.1 as 65002;
              neighbor 172.18.10.2 as 65002;

              ipv4 {
                import all;
                export where source = RTS_DEVICE;
              };

              hold time 90;
              keepalive time 30;
            }

            # Kernel protocol to sync routes
            protocol kernel {
              ipv4 {
                export all;
              };
            }
          '')
          (lib.mkIf (hostname == "xts2") ''
            log syslog all;
            router id 172.18.10.2;

            # Tailscale integration via direct protocol
            protocol direct {
              ipv4;
              interface "tailscale*";
            }

            # Device protocol for interface tracking
            protocol device {
              scan time 10;
            }

            # BGP protocol for peering with xts1
            protocol bgp xts1 {
              local 172.18.10.2 as 65002;
              neighbor 172.18.10.1 as 65002;

              ipv4 {
                import all;
                export where source = RTS_DEVICE;
              };

              hold time 90;
              keepalive time 30;
            }

            # Kernel protocol to sync routes
            protocol kernel {
              ipv4 {
                export all;
              };
            }
          '')
        ];
      };

      # BGP health check script for keepalived
      environment.etc."check-bgp-session.sh" = {
        text = ''
          #!/bin/sh
          # Check if BIRD daemon is running
          if ! systemctl is-active --quiet bird.service; then
            exit 1
          fi

          # Check if BGP session is established
          # birdc show protocols checks for Established state
          ${pkgs.bird2}/bin/birdc show protocols | grep -E 'BGP.*Established' > /dev/null

          exit $?
        '';
        mode = "0755";
      };

      # Bird exporter for Prometheus monitoring
      services.prometheus.exporters.bird = {
        enable = true;
        port = 9324;
        listenAddress = "0.0.0.0";
        openFirewall = false;
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
            interface = "eth0";
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
            ];
            extraConfig = ''
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

      # Open firewall for bird exporter on Tailscale interface
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        9324 # bird_exporter
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

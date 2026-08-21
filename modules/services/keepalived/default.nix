# Summary: NixOS module for Keepalived, configures high-availability IP failover for cluster nodes.
{
  hostname,
  lib,
  ...
}:

let
  # Define node-specific configurations.
  # fullNode = true for the bond0/bridge22 k8s-cluster servers (xsvr1-3): they carry
  # every VIP (k8s-gateway, network-gateway, kanidm-idm, kanidm-cluster), run bird +
  # tailscale (so the check_tailscale_subnet track_script and setup-vip-routing.sh
  # policy-routing apply), and restart bird/kanidm on VIP transition as appropriate.
  # fullNode = false for xidm1 (single-eth0 Sweet Potato SBC): it joins ONLY the
  # kanidm-idm VIP, as a last-resort member (lowest priority) below both xsvr1 and
  # xsvr2 — it has no bond0/bridge22/bird/tailscale, so those instances and the
  # tailscale-subnet health check / policy-routing notify hook don't apply to it.
  # runsKanidm = true only for nodes that actually run kanidm.service — the kanidm-idm
  # VRRP instance is scoped to these nodes only (xsvr3 excluded: it ran no kanidm.service
  # unit, so a dual xsvr1+xsvr2 failure previously could park the VIP on a node with
  # nothing listening — see kanidm-replace-xts2-with-xidm1 plan for the incident this fixes).
  nodeConfigs = {
    xsvr1 = {
      ip = "172.20.3.201";
      keepalivedState = "MASTER";
      keepalivedPriority = 101;
      interface = "bond0";
      fullNode = true;
      runsKanidm = true;
    };
    xsvr2 = {
      ip = "172.20.3.202";
      keepalivedState = "BACKUP";
      keepalivedPriority = 100;
      interface = "bond0";
      fullNode = true;
      runsKanidm = true;
    };
    xsvr3 = {
      ip = "172.20.3.203";
      keepalivedState = "BACKUP";
      keepalivedPriority = 99;
      interface = "bond0";
      fullNode = true;
      runsKanidm = false;
    };
    xidm1 = {
      ip = "172.20.1.111";
      keepalivedState = "BACKUP";
      keepalivedPriority = 90; # below xsvr1 (101) and xsvr2 (100) — last resort only
      interface = "eth0";
      fullNode = false;
      runsKanidm = true;
    };
  };

  vipAddress = "172.20.3.200";
  gatewayVipAddress = "172.20.1.101";
  kanidmVipAddress = "172.20.1.110";
  kanidmClusterVipAddress = "172.20.3.110";

  # Only set currentNode if hostname is in nodeConfigs
  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;
in

if currentNode == null then
  { }
else
  lib.mkMerge [
    {
      environment.etc."setup-vip-routing.sh" = lib.mkIf currentNode.fullNode {
        text = ''
          #!/bin/sh
          # Setup policy-based routing for VIP traffic

          # Ensure routing table exists
          if ! grep -q "100 vip_routing" /etc/iproute2/rt_tables 2>/dev/null; then
            echo "100 vip_routing" >> /etc/iproute2/rt_tables
          fi

          # Remove old rules (if any)
          ip rule del from ${gatewayVipAddress} table 100 2>/dev/null || true
          ip rule del from ${kanidmVipAddress} table 100 2>/dev/null || true

          # Add policy routing rules
          ip rule add from ${gatewayVipAddress} table 100 priority 100
          ip rule add from ${kanidmVipAddress} table 100 priority 101

          # Setup routing table 100
          ip route flush table 100 2>/dev/null || true
          ip route add 172.20.1.0/24 dev bond0 scope link table 100
          ip route add default via 172.20.1.250 dev bond0 table 100

          # Flush route cache
          ip route flush cache 2>/dev/null || true

          logger "VIP routing configured for ${gatewayVipAddress} and ${kanidmVipAddress}"
        '';
        mode = "0755";
      };

      # Define the script for keepalived to reference
      services.keepalived = {
        enable = true;
        vrrpScripts = lib.mkIf currentNode.fullNode {
          check_tailscale_subnet = {
            script = "/etc/check-tailscale-subnet.sh";
            interval = 2;
            weight = -2;
            fall = 3;
            rise = 2;
          };
        };
        vrrpInstances = lib.mkMerge [
          (lib.mkIf currentNode.fullNode {
            k8s-gateway = {
              state = currentNode.keepalivedState;
              interface = "bridge22";
              virtualRouterId = 51;
              priority = currentNode.keepalivedPriority;
              virtualIps = [
                { addr = "${vipAddress}/24"; }
              ];
              extraConfig = ''
                authentication {
                  auth_type PASS
                  auth_pass k8svip
                }
                track_script {
                  check_tailscale_subnet
                }
                notify_master "/run/current-system/systemd/bin/systemctl restart bird"
              '';
            };
            network-gateway = {
              state = currentNode.keepalivedState;
              interface = "bond0";
              virtualRouterId = 52;
              priority = currentNode.keepalivedPriority;
              virtualIps = [
                {
                  addr = "${gatewayVipAddress}/24";
                  dev = "bond0";
                  label = "bond0:vip1";
                }
              ];
              extraConfig = ''
                authentication {
                  auth_type PASS
                  auth_pass networksvip
                }
                track_script {
                  check_tailscale_subnet
                }
                notify_master "/etc/setup-vip-routing.sh && /run/current-system/systemd/bin/systemctl restart bird"
              '';
            };
            kanidm-cluster = {
              state = currentNode.keepalivedState;
              interface = "bridge22";
              virtualRouterId = 54;
              priority = currentNode.keepalivedPriority;
              virtualIps = [
                {
                  addr = "${kanidmClusterVipAddress}/24";
                  dev = "bridge22";
                  label = "bridge22:kanidm";
                }
              ];
              extraConfig = ''
                authentication {
                  auth_type PASS
                  auth_pass kanidmclustervip
                }
                track_script {
                  check_tailscale_subnet
                }
                notify_master "/run/current-system/systemd/bin/systemctl restart kanidm"
              '';
            };
          })
          (lib.mkIf currentNode.runsKanidm {
            kanidm-idm = {
              state = currentNode.keepalivedState;
              interface = currentNode.interface;
              virtualRouterId = 53;
              priority = currentNode.keepalivedPriority;
              virtualIps = [
                {
                  addr = "${kanidmVipAddress}/24";
                  dev = currentNode.interface;
                  label = "${currentNode.interface}:vip2";
                }
              ];
              extraConfig =
                if currentNode.fullNode then
                  ''
                    authentication {
                      auth_type PASS
                      auth_pass kanidmvip
                    }
                    track_script {
                      check_tailscale_subnet
                    }
                    notify_master "/etc/setup-vip-routing.sh && /run/current-system/systemd/bin/systemctl restart kanidm"
                  ''
                else
                  # xidm1: no bond0/tailscale, so no policy-routing notify hook or
                  # tailscale-subnet health check — just restart kanidm on takeover.
                  ''
                    authentication {
                      auth_type PASS
                      auth_pass kanidmvip
                    }
                    notify_master "/run/current-system/systemd/bin/systemctl restart kanidm"
                  '';
            };
          })
        ];
      };
    }

    (lib.mkIf currentNode.fullNode {
      environment.etc."check-tailscale-subnet.sh" = {
        text = ''
          #!/bin/sh
          tailscale status --json | grep '"AdvertisedRoutes":' | grep '172.16.0.0/12' > /dev/null
          if [ $? -eq 0 ]; then
            exit 0
          else
            exit 1
          fi
        '';
        mode = "0755";
      };

      # Enable IP forwarding and configure RPF for asymmetric routing
      boot.kernel.sysctl = {
        "net.ipv4.conf.bond0.rp_filter" = 2; # Loose mode RPF
      };

      # Enable iproute2 for policy routing
      networking.iproute2.enable = true;

      # Ensure routing table is configured at boot
      networking.localCommands = ''
        # Create custom routing table entry
        if ! grep -q "100 vip_routing" /etc/iproute2/rt_tables 2>/dev/null; then
          echo "100 vip_routing" >> /etc/iproute2/rt_tables
        fi
      '';
    })

    {
      # mkDefault: xidm1 pulls in hosts/nixos-arm/common/performance.nix, which
      # already sets ip_forward = 1 for ARM boards generally — same effective value,
      # but a plain (non-mkDefault) duplicate definition is a hard eval error even
      # when both sides agree.
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = lib.mkDefault 1;
        "net.ipv4.conf.all.rp_filter" = 2;
      };

      # Open required ports in firewall for VRRP
      networking.firewall = {
        extraCommands = ''
          # Allow VRRP multicast
          iptables -A INPUT -d 224.0.0.18/32 -j ACCEPT
          iptables -A OUTPUT -d 224.0.0.18/32 -j ACCEPT
        '';
      };
    }
  ]

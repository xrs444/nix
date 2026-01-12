# Summary: NixOS module for Keepalived, configures high-availability IP failover for cluster nodes.
{
  hostname,
  lib,
  ...
}:

let
  # Define node-specific configurations
  nodeConfigs = {
    xsvr1 = {
      ip = "172.20.3.201";
      keepalivedState = "MASTER";
      keepalivedPriority = 101;
    };
    xsvr2 = {
      ip = "172.20.3.202";
      keepalivedState = "BACKUP";
      keepalivedPriority = 100;
    };
    xsvr3 = {
      ip = "172.20.3.203";
      keepalivedState = "BACKUP";
      keepalivedPriority = 99;
    };
  };

  vipAddress = "172.20.3.200";
  gatewayVipAddress = "172.20.1.101";
  kanidmVipAddress = "172.20.1.110";

  # Only set currentNode if hostname is in nodeConfigs
  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;
in

if currentNode == null then
  { }
else
  {

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

    environment.etc."setup-vip-routing.sh" = {
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
      vrrpScripts = {
        check_tailscale_subnet = {
          script = "/etc/check-tailscale-subnet.sh";
          interval = 2;
          weight = -2;
          fall = 3;
          rise = 2;
        };
      };
      vrrpInstances = {
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
            notify_master "/run/current-system/systemd/bin/systemctl restart frr"
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
            notify_master "/etc/setup-vip-routing.sh && /run/current-system/systemd/bin/systemctl restart frr"
          '';
        };
        kanidm-idm = {
          state = currentNode.keepalivedState;
          interface = "bond0";
          virtualRouterId = 53;
          priority = currentNode.keepalivedPriority;
          virtualIps = [
            {
              addr = "${kanidmVipAddress}/24";
              dev = "bond0";
              label = "bond0:vip2";
            }
          ];
          extraConfig = ''
            authentication {
              auth_type PASS
              auth_pass kanidmvip
            }
            track_script {
              check_tailscale_subnet
            }
            notify_master "/etc/setup-vip-routing.sh && /run/current-system/systemd/bin/systemctl restart kanidm"
          '';
        };
      };
    };

    # Enable IP forwarding and configure RPF for asymmetric routing
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.bond0.rp_filter" = 2; # Loose mode RPF
      "net.ipv4.conf.all.rp_filter" = 2;
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

    # Open required ports in firewall for VRRP
    networking.firewall = {
      extraCommands = ''
        # Allow VRRP multicast
        iptables -A INPUT -d 224.0.0.18/32 -j ACCEPT
        iptables -A OUTPUT -d 224.0.0.18/32 -j ACCEPT
      '';
    };
  }

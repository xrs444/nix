{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  # Define node-specific configurations
  nodeConfigs = {
    xsvr1 = {
      ip = "172.20.3.201";
      routerId = "172.20.3.201";
      keepalivedState = "MASTER";
      keepalivedPriority = 101;
    };
    xsvr2 = {
      ip = "172.20.3.202";
      routerId = "172.20.3.202";
      keepalivedState = "BACKUP";
      keepalivedPriority = 100;
    };
    xsvr3 = {
      ip = "172.20.3.203";
      routerId = "172.20.3.203";
      keepalivedState = "BACKUP";
      keepalivedPriority = 99;
    };
  };

  frrASN = 65000;
  ciliumASN = 65001;
  ciliumIPs = [ "172.20.3.10" "172.20.3.20" "172.20.3.30" ];
  vipAddress = "172.20.3.200";
  gatewayVipAddress = "172.20.1.101";

  # List of all node IPs
  allNodeIPs = map (node: node.ip) (lib.attrValues nodeConfigs);

  # Only set currentNode if hostname is in nodeConfigs
  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;
in

if currentNode == null then
  {}
else
  {

    # Enable FRR routing daemon
    services.frr = {
      bgpd.enable = true;
      config = ''
        router bgp ${toString frrASN}
          bgp router-id ${currentNode.routerId}
          neighbor CILIUM peer-group
          neighbor CILIUM remote-as ${toString ciliumASN}
          neighbor CILIUM ebgp-multihop 4
          neighbor CILIUM timers 3 9
          neighbor CILIUM timers connect 15
          neighbor CILIUM update-source 172.20.3.200

          neighbor CILIUM route-map CILIUM-IN in
          neighbor CILIUM route-map CILIUM-OUT out

          bgp listen range 172.20.3.0/24 peer-group CILIUM

          address-family ipv4 unicast
            neighbor CILIUM activate
          exit-address-family
        !
        route-map CILIUM-IN permit 10
        !
        route-map CILIUM-OUT permit 10
      '';

    };

    # Add this block to override the systemd unit for bgpd
    systemd.services.frr-bgpd = {
      serviceConfig.SupplementaryGroups = [ "keys" ];
    };

    # Add this to your top-level attribute set (alongside services.frr, services.keepalived, etc.)
    environment.etc."check-frr.sh".text = ''
      #!/bin/sh
      systemctl is-active frr
    '';
    environment.etc."check-frr.sh".mode = "0755";

    environment.etc."check-tailscale-subnet.sh".text = ''
      #!/bin/sh
      tailscale status --json | grep '"AdvertisedRoutes":' | grep '172.16.0.0/12' > /dev/null
      if [ $? -eq 0 ]; then
        exit 0
      else
        exit 1
      fi
    '';
    environment.etc."check-tailscale-subnet.sh".mode = "0755";

    # Enable keepalived for VIP
    services.keepalived = {
      enable = true;
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
          virtualRouterId = 51;
          priority = currentNode.keepalivedPriority;
          virtualIps = [
            { addr = "${gatewayVipAddress}/24"; }
          ];
          extraConfig = ''
            authentication {
              auth_type PASS
              auth_pass networksvip
            }
            track_script {
              check_tailscale_subnet
            }
            notify_master "/run/current-system/systemd/bin/systemctl restart frr"
          '';
        };
      };
    };

    # Open required ports in firewall
    networking.firewall = {
      allowedTCPPorts = [ 179 ]; # BGP port
      allowedUDPPorts = [ ];
      extraCommands = ''
        # Allow VRRP multicast
        iptables -A INPUT -d 224.0.0.18/32 -j ACCEPT
        iptables -A OUTPUT -d 224.0.0.18/32 -j ACCEPT
      '';
    };
  }

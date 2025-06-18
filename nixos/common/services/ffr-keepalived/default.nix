{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  # Define node-specific configurations
  nodeConfigs = {
    xsvr1 = {
      ip = "172.20.1.10";
      routerId = "172.20.1.10";
      keepalivedState = "MASTER";
      keepalivedPriority = 101;
    };
    xsvr2 = {
      ip = "172.20.1.20";
      routerId = "172.20.1.20";
      keepalivedState = "BACKUP";
      keepalivedPriority = 100;
    };
    xsvr3 = {
      ip = "172.20.1.30";
      routerId = "172.20.1.30";
      keepalivedState = "BACKUP";
      keepalivedPriority = 99;
    };
  };

  frrASN = 65000;
  ciliumASN = 65001;
  ciliumIPs = [ "172.20.3.10" "172.20.3.20" "172.20.3.30" ];
  vipAddress = "172.20.1.101";

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
          bgp router-id ${vipAddress}
          bgp listen range 172.20.3.0/24 peer-group CILIUM

          neighbor CILIUM peer-group
          neighbor CILIUM remote-as ${toString ciliumASN}
          neighbor CILIUM ebgp-multihop 4
          neighbor CILIUM timers 3 9
          neighbor CILIUM timers connect 15
          neighbor CILIUM update-source ${vipAddress}

          # Add route maps directly in the config string
          neighbor CILIUM route-map CILIUM-IN in
          neighbor CILIUM route-map CILIUM-OUT out

          address-family ipv4 unicast
            redistribute connected
            redistribute static
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

    # Enable keepalived for VIP
    services.keepalived = {
      enable = true;
      vrrpInstances = {
        k8s-gateway = {
          state = currentNode.keepalivedState;
          interface = "bond0";
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
              check_frr
            }
            notify_master "/run/current-system/systemd/bin/systemctl restart frr"
          '';
        };
      };
      extraConfig = ''
        vrrp_script check_frr {
          script "/etc/check-frr.sh"
          interval 2
          weight -2
          fall 3
          rise 2
        }
      '';
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

    # Enable IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkForce 1;
      "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
    };
  }

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

  frrASN = 65000;         # <-- Add your ASN here
  metallbASN = 65001;     # <-- Add your MetalLB ASN here
  metallbIPs = [ "172.20.3.10" "172.20.3.20" "172.20.3.30" ]; # Or use the MetalLB speaker IPs if you have more than one
  vipAddress = "172.20.1.101"; # <-- Add your VIP address here

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
        frr version 8.4
        frr defaults traditional
        hostname ${hostname}
        log syslog informational
        no ipv6 forwarding
        service integrated-vtysh-config
        !
        router bgp ${toString frrASN}
         bgp router-id ${currentNode.routerId}
         ${lib.concatMapStringsSep "\n " (ip: "neighbor ${ip} remote-as ${toString metallbASN}") metallbIPs}
         !
         address-family ipv4 unicast
          network 172.21.0.0/24
          ${lib.concatMapStringsSep "\n  " (ip: "neighbor ${ip} activate") metallbIPs}
         exit-address-family
        !
        line vty
        !
      '';
    };

    # Enable keepalived for VIP
    services.keepalived = {
      enable = true;
      vrrpInstances = {
        k8s-gateway = {
          state = currentNode.keepalivedState;
          interface = "bond0"; # Adjust if your interface is different
          virtualRouterId = 51;
          priority = currentNode.keepalivedPriority;
          virtualIps = [
            { addr = "${vipAddress}/24"; }
          ];
          extraConfig = ''
            authentication {
              auth_type PASS
              auth_pass k8s-cluster-vip
            }
            track_script {
              check_frr
            }
          '';
        };
      };
      extraConfig = ''
        vrrp_script check_frr {
          script "/run/current-system/sw/bin/systemctl is-active frr"
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

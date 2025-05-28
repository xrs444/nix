# flake.nix or shared configuration module
{ config, lib, pkgs, hostname, ... }:

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
      keepalivedPriority = 100;
    };
  };

  # Get current node config based on hostname
  currentNode = nodeConfigs.${hostName};
  
  # All node IPs for BGP neighbors
  allNodeIPs = lib.attrValues (lib.mapAttrs (name: cfg: cfg.ip) nodeConfigs);
  
  # VIP configuration
  vipAddress = "172.20.1.101";
  metallbASN = 65001;
  frrASN = 65000;

in {
  # Enable FRR routing daemon
  services.frr = {
    enable = true;
    bgp.enable = true;
    config = ''
      frr version 8.4
      frr defaults traditional
      hostname ${hostName}
      log syslog informational
      no ipv6 forwarding
      service integrated-vtysh-config
      !
      router bgp ${toString frrASN}
       bgp router-id ${currentNode.routerId}
       ${lib.concatMapStringsSep "\n " (ip: "neighbor ${ip} remote-as ${toString metallbASN}") allNodeIPs}
       !
       address-family ipv4 unicast
        network 172.21.0.0/24
        ${lib.concatMapStringsSep "\n  " (ip: "neighbor ${ip} activate") allNodeIPs}
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
        advert_int = 1;
        authentication = {
          auth_type = "PASS";
          auth_pass = "k8s-cluster-vip";
        };
        virtualIps = [
          "${vipAddress}/24"
        ];
        extraConfig = ''
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
    lib.mkforce "net.ipv4.ip_forward" = 1;
    lib.mkforce    "net.ipv6.conf.all.forwarding" = 1;
  };
}

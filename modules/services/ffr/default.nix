# Summary: NixOS module for FFR routing service, sets up node-specific router configurations for cluster hosts.
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
      routerId = "172.20.3.201";
    };
    xsvr2 = {
      ip = "172.20.3.202";
      routerId = "172.20.3.202";
    };
    xsvr3 = {
      ip = "172.20.3.203";
      routerId = "172.20.3.203";
    };
  };

  frrASN = 65000;
  ciliumASN = 65001;

  # Only set currentNode if hostname is in nodeConfigs
  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;
in

if currentNode == null then
  { }
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

    # Add health check script for FRR
    environment.etc."check-frr.sh".text = ''
      #!/bin/sh
      systemctl is-active frr
    '';
    environment.etc."check-frr.sh".mode = "0755";

    # Open required ports in firewall
    networking.firewall = {
      allowedTCPPorts = [ 179 ]; # BGP port
    };
  }

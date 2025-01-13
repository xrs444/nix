{ pkgs, lib, ... }:
{

  networking.hostId = "8f9996ca";
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    netdevs = {
      "10-bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer2+3";
          MIIMonitorSec = "0.100s";
          LACPTransmitRate = "fast";
        };
      };
      "20-vlan17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan-17";
         };
         vlanConfig.Id = 17;
      };
      "20-bridge17" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge17";
        };
      };
    };
    networks = {
      "30-enp2s0f0" = {
        matchConfig.Name = "enp2s0f0";
        networkConfig.Bond = "bond0";
      };
      "30-enp2s0f1" = {
        matchConfig.Name = "enp2s0f1";
        networkConfig.Bond = "bond0";
      };
      "40-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
        vlan = [
          "vlan17"
        ];
      };
      "50-bridge17" = {
        matchConfig.Name = "bridge17";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
    };
  };
}

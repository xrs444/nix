{ pkgs, lib, ... }:
{

  networking.hostId = "0814bb9a";
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    netdevs = {
      "bond0" = {
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
      "bond0.17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.17";
         };
         vlanConfig.Id = 17;
      };
      "bridge17" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge17";
        };
      };
      "bond0.16" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.16";
         };
         vlanConfig.Id = 16;
      };
      "bridge16" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge16";
        };
      };
      "bond0.13" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.13";
         };
         vlanConfig.Id = 13;
      };
      "bridge13" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge13";
        };
      };
    };
    networks = {
      "10-enp3s0f0" = {
        matchConfig.Name = "enp3s0f0";
        networkConfig.Bond = "bond0";
      };
      "20-enp3s0f1" = {
        matchConfig.Name = "enp3s0f1";
        networkConfig.Bond = "bond0";
      };
      "30-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
      "40-eno1" = {
        matchConfig.Name = "eno1";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
      "45-bond0.17" = {
        matchConfig.Name = "bond0.17";
        networkConfig.Bridge = "bridge17";
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "50-bridge17" = {
        matchConfig.Name = "bridge17";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "55-bond0.16" = {
        matchConfig.Name = "bond0.16";
        networkConfig.Bridge = "bridge16";
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "60-bridge16" = {
        matchConfig.Name = "bridge16";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "55-bond0.13" = {
        matchConfig.Name = "bond0.13";
        networkConfig.Bridge = "bridge13";
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "60-bridge13" = {
        matchConfig.Name = "bridge13";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
    };
  };
}

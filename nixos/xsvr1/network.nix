{ pkgs, lib, ... }:
{

  networking.hostId = "0814bb9a";
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    netdevs = {
      "1-enp14s0u10u2c2" = {
        enable = false;
      };
      "5-bond0" = {
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
      "10-bond0.13" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.13";
         };
         vlanConfig.Id = 13;
      };
      "15-bond0.16" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.16";
         };
         vlanConfig.Id = 16;
      };
     "20-bond0.17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.17";
         };
         vlanConfig.Id = 17;
      };
      "25-bridge13" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge13";
        };
      };
      "30-bridge16" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge16";
        };
      };
      "35-bridge17" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge17";
        };
      };
    };
    networks = {
      "40-enp3s0f0" = {
        matchConfig.Name = "enp3s0f0";
        networkConfig.Bond = "bond0";
        linkConfig.RequiredForOnline = "enslaved";
      };
      "40-enp3s0f1" = {
        matchConfig.Name = "enp3s0f1";
        networkConfig.Bond = "bond0";
        linkConfig.RequiredForOnline = "enslaved";
      };
      "50-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
      };
      "55-bond0.17" = {
        matchConfig.Name = "bond0.17";
        networkConfig = {
          Bridge = "bridge17";
          DHCP = false;
          IPv6AcceptRA = false;
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "60-bridge17" = {
        matchConfig.Name = "bridge17";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "75-bond0.16" = {
        matchConfig.Name = "bond0.16";
        networkConfig ={ 
          Bridge = "bridge16";
          DHCP = false;
          IPv6AcceptRA = false;
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "80-bridge16" = {
        matchConfig.Name = "bridge16";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "85-bond0.13" = {
        matchConfig.Name = "bond0.13";
        networkConfig = {
          Bridge = "bridge13";
          DHCP = false;
          IPv6AcceptRA = false;
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "90-bridge13" = {
        matchConfig.Name = "bridge13";
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
    };
 };
}
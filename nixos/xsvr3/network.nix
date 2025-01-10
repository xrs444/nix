{ pkgs, lib, ... }:
{

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
    };
    networks = {
      "10-enp1s0f0" = {
        matchConfig.Name = "enp1s0f0";
        networkConfig.Bond = "bond0";
      };
      "20-enp1s0f1" = {
        matchConfig.Name = "enp1s0f1";
        networkConfig.Bond = "bond0";
      };
      "30-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };
}
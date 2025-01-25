{ pkgs, lib, ... }:
{

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
    "20-wlo1" = {
      netdevConfig = {
        Kind = "wireless";
        Name = "wlo10";
        enable = false;
      };
    };
    networks = {
      "30-enp1s0f0" = {
        matchConfig.Name = "enp1s0f0";
        networkConfig.Bond = "bond0";
      };
      "40-enp1s0f1" = {
        matchConfig.Name = "enp1s0f1";
        networkConfig.Bond = "bond0";
      };
      "50-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
    };
  };
}
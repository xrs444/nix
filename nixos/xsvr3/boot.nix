{ pkgs, lib, ... }:
{
  boot = {
    loader.systemd-boot.enable = true;

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod" 
      ];
      kernelModules = [
        "kvm-intel" 
      ];
    };
    
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "Bond0" = {
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
    };
    networks = {
      "20-enp1s0f0" = {
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
      "40-eno2" = {
        matchConfig.Name = "eno2";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
      # Added configuration for VLAN interface
      "45-bond0.17" = {
        matchConfig.Name = "bond0.17";
        networkConfig.Bridge = "bridge17";
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

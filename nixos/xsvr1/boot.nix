{ pkgs, lib, ... }:
{

  networking.useNetworkd = true;

  boot = {
    loader.systemd-boot.enable = true;

    initrd = {
      availableKernelModules = [
        "mpt3sas"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod" 
      ];
      kernelModules = [
        "kvm-amd" 
      ];
    };

    swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
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
#          MinLinks = "1";
          AdActorSystemPriority = "65535";
          AdSelectPolicy = "stable";
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
      "20-enp3s0f0" = {
        matchConfig.Name = "enp3s0f0";
        networkConfig.Bond = "bond0";
      };
      "20-enp3s0f1" = {
        matchConfig.Name = "enp3s0f1";
        networkConfig.Bond = "bond0";
      };
      "30-bond0" = {
        matchConfig.Name = "bond0";
        linkConfig.RequiredForOnline = "carrier";
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

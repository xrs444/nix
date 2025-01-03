{ pkgs, lib, ... }:
{
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

  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    netdevs = {
      "10G-Bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer3+4";
          MIIMonitorSec = "0.100s";
          LACPTransmitRate = "fast";
          MinLinks = "1";
          AdActorSystemPriority = "65535";
          AdSelectPolicy = "stable";
        };
      };
      "bond0.17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.17";
          Id = 17;
          Interface = "bond0";
        };
      };
      "bridge17" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge17";  # Changed to match the netdev name
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
        networkConfig.DHCP = "yes";
      };
      "40-eno1" = {
        matchConfig.Name = "eno1";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig.DHCP = "yes";
      };
      # Added configuration for VLAN interface
      "45-bond0.17" = {
        matchConfig.Name = "bond0.17";
        networkConfig.Bridge = "bridge17";
      };
      "50-bridge17" = {
        matchConfig.Name = "bridge17";  # Changed to match the netdev name
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
    };
  };
}

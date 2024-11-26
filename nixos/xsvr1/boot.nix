{ pkgs, lib, ... }:
{
  boot = {
    # Secure boot configuration
    loader.systemd-boot.enable = lib.mkForce false;

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

}

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
        MIIMonitorSec="0.100s";
      };
    };
    "bond0.17" = {
      netdevConfig = {
        id = 17;
        interface = "bond0";
    };
    "bridge17" = {
      netdevConfig = {
        kind = "bridge";
        Name "br17";
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
    "50-br17" = {
      matchConfig = "br17";
      bridgeConfig = {};
      linkConfig = {
        RequiredForOnline = "carrier";
      };
    };
  };
 };
}
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

networking.useNetworks = true;
systemd.network = { 

  enable = true;
  netdevs = {
    "10G-Bond0" = {
      Kind = "bond";
      Name = "bond0";
    };
    bondConfig = {
      Mode = "802.3ad";
      MIIMonitorSec="0.100s";
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
  };
}
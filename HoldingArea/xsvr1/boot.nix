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
        "kvm-intel" 
      ];
    };

    swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
    };
  };
}

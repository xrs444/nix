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
}

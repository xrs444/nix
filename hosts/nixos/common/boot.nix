# Common boot configuration for NixOS hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    
    # Common kernel modules that most systems need
    initrd.availableKernelModules = lib.mkDefault [
      "xhci_pci"
      "ahci" 
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
  };
}
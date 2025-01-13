{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./disks.nix
    ./network.nix
  ];

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

  swraid = {
    enable = true;
    mdadmConf = "PROGRAM=true";
  };

  powerManagement.cpuFreqGovernor = "performance";
}

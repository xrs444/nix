{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: 
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-ssd
    ./nixos/modules/apps
    ./nixos/modules/services
    ./hardware-configuration.nix
    ./disks.nix
  ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "uas"
      "usbhid"
      "sd_mod"
      "xhci_pci"
    ];
    kernelModules = [
      "kvm-amd"
    ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
    };
  };


    
  }
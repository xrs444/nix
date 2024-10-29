{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: 
{
  imports = [
    inputs.determinate.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./nixos/modules/apps
    ./nixos/modules/services
    ./${hostname}
    ./hardware-configuration.nix
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

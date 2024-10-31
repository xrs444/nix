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
    (modulesPath + "/installer/scan/not-detected.nix")
    ./nixos/_elements/apps
    ./nixos/_elements/services
    ./hardware-configuration.nix
    ./disks.nix
  ];

  boot = {
    initrd.availableKernelModules = [
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
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
    };
    boot.swraid.enable = true;
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  networking = {
   useDHCP = lib.mkDefault true;
  };
}

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
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    ./disks.nix
#    ./network.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
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
    };
  };

services.spice-vdagentd.enable = true;
services.qemuGuest.enable = true;

}

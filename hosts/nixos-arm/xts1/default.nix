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
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ../common/boot.nix
    ./disks.nix
#    ./network.nix
  ];

  # Bootloader configuration for Raspberry Pi
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Enable I2C if needed for POE HAT
  hardware.i2c.enable = true;

  # Ensure system state version is set
  system.stateVersion = lib.mkDefault "24.05";
}
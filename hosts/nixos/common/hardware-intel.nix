# Common Intel hardware configuration
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Platform and architecture
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Enable firmware for hardware devices (WiFi adapters, etc.)
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Intel virtualization
  boot.initrd.kernelModules = lib.mkDefault [
    "kvm-intel"
  ];
}
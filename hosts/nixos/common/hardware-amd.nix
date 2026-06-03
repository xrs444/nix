# Common AMD hardware configuration
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
  ];

  # Platform and architecture
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Enable firmware for hardware devices (WiFi adapters, etc.)
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # AMD-specific settings
  hardware.cpu.amd.updateMicrocode = lib.mkForce true;

  # AMD virtualization
  boot.initrd.kernelModules = lib.mkDefault [
    "kvm-amd"
    "amdgpu"
  ];
}
# Placeholder hardware configuration for xdash-k
# This will be replaced with actual hardware-configuration.nix during installation
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Placeholder filesystem configuration
  # Will be replaced by nixos-generate-config during installation
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];
}

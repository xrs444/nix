# Common NixOS ARM-specific configuration
# This module provides base configurations that are common across NixOS ARM hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./boot.nix
    ./performance.nix
  ];
  
  # Platform default for ARM systems (can be overridden by hardware-specific modules)
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
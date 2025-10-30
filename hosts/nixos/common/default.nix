# Common NixOS-specific configuration
# This module provides base configurations that are common across NixOS hosts
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
  
  # Platform default (can be overridden by hardware-specific modules)
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
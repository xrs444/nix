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

  options.minimalImage = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "If true, build a minimal image (skip heavy modules like letsencrypt).";
  };

  config = {
    # Platform default for ARM systems (can be overridden by hardware-specific modules)
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
    sdImage.populateRootCommands = "";
    sdImage.populateFirmwareCommands = "";
  };
}
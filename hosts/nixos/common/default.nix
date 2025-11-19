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
  ];

  options.minimalImage = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "If true, build a minimal image (skip heavy modules like letsencrypt).";
  };
}
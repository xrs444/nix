# Common performance settings for NixOS hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # CPU frequency governor for performance
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
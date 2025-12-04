# Summary: Common NixOS configuration for x86_64 hosts, imports base modules and sets hostname.
{
  config,
  lib,
  pkgs,
  hostname,
  inputs,
  username,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/performance.nix
    # Add other heavy modules here as needed
  ];

  networking.hostName = hostname;

  # Only put truly shared/common settings here
}

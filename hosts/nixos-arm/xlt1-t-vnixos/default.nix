# Summary: NixOS ARM host configuration for xlt1-t-vnixos, imports hardware, disk, and desktop modules.
{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  system,
  config,
  ...
}@args:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-arm64-server.nix
    ./disks.nix
    ./desktop.nix
    #    ./network.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  nixpkgs.hostPlatform = platform;

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;
}

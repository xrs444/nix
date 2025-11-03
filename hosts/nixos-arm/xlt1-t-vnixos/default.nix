{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  system,
  ...
} @ args:
{
  imports = [
    ../common/hardware-arm64-server.nix
    ./disks.nix
    ./desktop.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = platform;

}
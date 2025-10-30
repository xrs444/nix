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
    ./disks.nix
    ./desktop.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = platform;

}
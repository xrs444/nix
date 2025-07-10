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
#    ./network.nix
  ];
  nixpkgs.hostPlatform = platform;

  system.stateVersion = "25.05";
}
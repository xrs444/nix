{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
} @ args:
{
  imports = [
    (import ../common/services args)
    ./disks.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = platform;

  system.stateVersion = "25.05";
}
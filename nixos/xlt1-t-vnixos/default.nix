{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
{
  imports = [
    ./disks.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "25.05";

}
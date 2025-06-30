{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./disks.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = "aarch64-linux";

}
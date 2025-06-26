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
    ./network.nix
  ];
  nixpkgs.hostPlatform = "x86_64-linux";

}
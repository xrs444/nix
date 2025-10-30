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
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ./disks.nix
    ./network.nix
    ./desktop.nix
  ];
}
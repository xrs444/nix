{ config, lib, inputs, hostname, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];
}
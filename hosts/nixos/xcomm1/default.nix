# Summary: NixOS host configuration for xcomm1, imports hardware, audio, and disk modules.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./disks.nix
    # Common imports are now handled by hosts/common/default.nix
  ];
  nixpkgs.config.allowUnfree = true;
}

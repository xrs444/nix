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
    inputs.disko.nixosModules.disko
    # Common imports are now handled by hosts/common/default.nix
  ];
  nixpkgs.config.allowUnfree = true;
}

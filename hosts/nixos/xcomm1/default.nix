{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
{
  imports = [
    (import (inputs.self + /modules/packages-common/default.nix))
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
    (import (inputs.self + /modules/services/default.nix) { inherit config lib pkgs; })
  ];
  nixpkgs.config.allowUnfree = true;
}

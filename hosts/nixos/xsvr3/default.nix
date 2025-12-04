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
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./desktop.nix
    ./serial.nix
    ./vms.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
    (import (inputs.self + /modules/services/default.nix) { inherit config lib pkgs; })
  ];
  # Add other heavy modules here as needed

  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
}

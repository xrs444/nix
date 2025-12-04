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
    ../common/boot.nix
    ../common/vm-guest.nix
    ./desktop.nix
    #    ./network.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
    (import (inputs.self + /modules/services/default.nix) { inherit config lib pkgs; })
  ];
  # Add other heavy modules here as needed

  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
      ];
    };
  };
  nixpkgs.config.allowUnfree = true;
}

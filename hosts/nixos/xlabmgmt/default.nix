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
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/vm-guest.nix
    ./desktop.nix
    #    ./network.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
    # Common imports are now handled by hosts/common/default.nix
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

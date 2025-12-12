# Summary: NixOS host configuration for xlabmgmt, imports hardware, boot, VM guest, and disk modules.
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

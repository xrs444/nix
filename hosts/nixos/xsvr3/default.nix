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
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./desktop.nix
    ./serial.nix
    ./vms.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
    # Common imports are now handled by hosts/common/default.nix
  ];
  # Add other heavy modules here as needed

  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
}

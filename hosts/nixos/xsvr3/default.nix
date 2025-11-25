{ config, lib, inputs, hostname, ... }:
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
    # Add other heavy modules here as needed
  ];

  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
}


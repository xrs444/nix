{ config, lib, pkgs, hostname, inputs, username, ... }:
{
  options.minimalImage = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "If true, build a minimal image (skip heavy modules like letsencrypt).";
  };

  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./vms.nix
    # Add other heavy modules here as needed
  ];

  networking.hostName = hostname;

  # Only put truly shared/common settings here
}
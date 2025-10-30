# NixOS ARM platform configuration
{
  config,
  hostname,
  isInstall,
  isWorkstation,
  inputs,
  lib,
  modulesPath,
  outputs,
  pkgs,
  platform ? null,
  stateVersion,
  username,
  ...
}:
{
  imports = [
    # Base NixOS configuration shared with x86_64
    ../base-nixos.nix
    # Platform-specific common configuration
    ./common
    # Host-specific configuration
    ./${hostname}
  ];

  # Platform-specific nixpkgs configuration
  nixpkgs = {
    hostPlatform = if platform != null then platform else lib.mkDefault "aarch64-linux";
    # overlays and config are set in ../common
  };
}
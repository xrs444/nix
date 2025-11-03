# Base NixOS configuration shared between x86_64 and ARM platforms
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
    # Temporarily comment out ALL imports to find the circular dependency
    # inputs.determinate.nixosModules.default
    # inputs.disko.nixosModules.disko
    # inputs.nix-flatpak.nixosModules.nix-flatpak
    # inputs.nix-index-database.nixosModules.nix-index
    # inputs.nix-snapd.nixosModules.default
    # inputs.sops-nix.nixosModules.sops
    # inputs.comin.nixosModules.comin
    # (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Minimal config just to test
  system.stateVersion = stateVersion;
}
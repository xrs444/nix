# Base NixOS configuration shared between x86_64 and ARM platforms
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  hostname,
  username,
  stateVersion,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
  ];

  # Install nixos-needsreboot as a package instead of importing as a module
  environment.systemPackages = with pkgs; [
    inputs.nixos-needsreboot.packages.${pkgs.system}.default
  ];

  # Minimal config just to test
  system.stateVersion = stateVersion;
}
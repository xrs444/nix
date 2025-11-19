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
    inputs.comin.nixosModules.comin
    ../modules/users
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure sops-nix to use the age key file
  sops = {
    age.keyFile = "/var/lib/private/sops/age/keys.txt";
  };

  # Overlays are now applied in lib/default.nix at the nixpkgs instantiation level
  # This ensures they're available before any module evaluation happens

  # Minimal config just to test
  system.stateVersion = stateVersion;
}
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
  overlays,
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
    ../hosts/nixos/common/services.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Configure sops-nix to use the age key file
  sops = {
    age.keyFile = "/etc/ssh/sops-age-key.txt";
    defaultSopsFile = "/secrets/wan-wifi.yaml";
  };

  system.stateVersion = stateVersion;

  nixpkgs.config.allowUnfree = true;
}

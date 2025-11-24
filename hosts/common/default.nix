# Common configuration for all systems (NixOS, NixOS-ARM, Darwin)
{
  config,
  inputs,
  lib,
  outputs,
  username ? "thomas-local",
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  # Option to build a minimal image (skip heavy modules)
  options.minimalImage = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Build a minimal image for initial boot, skipping heavy modules.";
  };

  # Common Nix configuration
  nix = {
    settings = {
      # Core Nix settings
      experimental-features = "flakes nix-command";
      flake-registry = "";
      trusted-users = [
        "root"
        "${username}"
      ];
      warn-dirty = false;
      # Default cache configuration for all systems
      substituters = [
        "http://nixcache.xrs444.net?priority=10"
        "https://cache.nixos.org?priority=20"
      ];
    };
    # Flake registry and nixPath setup
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Common bootloader and disko settings for NixOS (x86_64)
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  disko.enable = lib.mkDefault true;

  # Common nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };
}
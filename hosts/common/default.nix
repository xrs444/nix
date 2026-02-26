# Common configuration for all systems (NixOS, NixOS-ARM, Darwin)
{
  inputs,
  lib,
  username ? "thomas-local",
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  imports = [
    ../../modules/packages-common
    ../../modules/services
    # Add other truly universal imports here
  ];

  # Option to build a minimal image (skip heavy modules)
  options.minimalImage = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Build a minimal image for initial boot, skipping heavy modules.";
  };

  config = {
    # Common Nix configuration (experimental-features already set in base-nixos.nix)
    nix.settings.flake-registry = "";
    nix.settings.trusted-users = [
      "root"
      "${username}"
    ];
    nix.settings.warn-dirty = false;
    nix.settings.substituters = [
      "http://xsvr1.lan?priority=10"
      "https://cache.nixos.org?priority=20"
    ];
    nix.settings.trusted-public-keys = [
      "xsvr1.lan-1:zYWtshSYClLIckawdxzJEuy82yifQX2pbultumrToKI="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    # Use proper flake registry without builtins.toFile warnings
    nix.registry = lib.mapAttrs (_: flake: {
      flake = flake;
    }) flakeInputs;
    nix.nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    # Common nixpkgs configuration
    nixpkgs.config.allowUnfree = true;
  };
}

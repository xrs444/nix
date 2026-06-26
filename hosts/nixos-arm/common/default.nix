# Summary: Common NixOS ARM configuration, sets base options and imports modules for ARM hosts.
# Common NixOS ARM-specific configuration
# This module provides base configurations that are common across NixOS ARM hosts
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./boot.nix
    ./performance.nix
  ];

  config = {
    # Platform default for ARM systems (can be overridden by hardware-specific modules)
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
    # Headless ARM servers don't need udisks2; it transitively pulls in harfbuzz/pango.
    # Desktop ARM hosts (xlt1-t-vnixos) re-enable this in their desktop.nix.
    services.udisks2.enable = lib.mkForce false;
  };
}

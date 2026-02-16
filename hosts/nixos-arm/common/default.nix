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
    sdImage.populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
    sdImage.populateFirmwareCommands = "";
  };
}

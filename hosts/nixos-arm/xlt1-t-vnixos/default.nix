{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  system,
  config,
  ...
}@args:
{
  imports = [
    (import (inputs.self + /modules/packages-common/default.nix))
    ../../base-nixos.nix
    ../common/hardware-arm64-server.nix
    ./disks.nix
    ./desktop.nix
    #    ./network.nix
    (import (inputs.self + /modules/services/default.nix) { inherit config lib pkgs; })
  ];

  nixpkgs.hostPlatform = platform;

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;
}

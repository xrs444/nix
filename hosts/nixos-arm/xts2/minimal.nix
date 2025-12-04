{ pkgs, inputs, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-arm64-server.nix
    ../common/boot.nix
    ./disks.nix
    (import (inputs.self + /modules/sdImage/custom.nix))
  ];
}

{ pkgs, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-arm64-server.nix
    ../common/boot.nix
    ./disks.nix
    ../../../modules/packages-nixos/bootstrap/minimal.nix
  ];
}

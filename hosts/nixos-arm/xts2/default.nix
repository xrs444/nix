# Summary: NixOS ARM host configuration for xts2, imports boot and disk modules.
# Boot: UEFI from SPI flash (LibreTech firmware). No U-Boot activation script needed.
{ hostname, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/boot.nix
    ../common/performance.nix
    ../common/hardware-sweet-potato.nix
    ./disks.nix
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;
}

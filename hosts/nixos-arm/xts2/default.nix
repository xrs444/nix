# Summary: NixOS ARM host configuration for xts2, imports boot and disk modules.
{ hostname, pkgs, ... }:
let
  uboot = pkgs.ubootLibreTechCC.overrideAttrs (o: {
    meta = o.meta // { broken = false; };
  });
in
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

  # Re-flash U-Boot on every NixOS switch. Disko overwrites the sectors U-Boot
  # occupies when it (re)partitions the disk, so we need to restore it each
  # activation to keep the board bootable after deploys.
  system.activationScripts.flashUboot.text = ''
    ${pkgs.coreutils}/bin/dd \
      if=${uboot}/u-boot.gxl.sd.bin \
      of=/dev/by-id/mmc-SR128_0xeec59d30 \
      conv=fsync,notrunc bs=512 skip=1 seek=1
    ${pkgs.coreutils}/bin/dd \
      if=${uboot}/u-boot.gxl.sd.bin \
      of=/dev/by-id/mmc-SR128_0xeec59d30 \
      conv=fsync,notrunc bs=1 count=444
  '';

  nixpkgs.config.allowUnfree = true;
}

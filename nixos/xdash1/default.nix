{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ]; 
  };
  nixpkgs.hostPlatform = "aarch64-linux";

}
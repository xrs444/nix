{ pkgs, inputs, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    (import (inputs.self + /modules/sdImage/custom.nix))
  ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
}

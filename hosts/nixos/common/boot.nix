# Common boot configuration for NixOS hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };

  };
}

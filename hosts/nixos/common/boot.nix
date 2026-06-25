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
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 5;
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
    };

  };
}

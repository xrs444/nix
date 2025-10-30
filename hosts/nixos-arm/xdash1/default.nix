{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
{
  imports = [
    ../common/hardware-rpi.nix
    ./network.nix
  ];

  # Platform is set by ../common/hardware-rpi.nix

  environment.systemPackages = with pkgs; [
    labwc
  ];
}


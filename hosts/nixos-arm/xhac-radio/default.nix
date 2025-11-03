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

  environment.systemPackages = with pkgs; [
    labwc
  ];
}


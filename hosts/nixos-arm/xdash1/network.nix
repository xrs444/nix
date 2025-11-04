{ pkgs, lib, platform, ... }:
{
  networking = {
    hostName = "xdash1";
    networkmanager.enable = true;  # Or configure static IP if needed
  };
}
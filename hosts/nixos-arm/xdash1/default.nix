{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-orangepi.nix
    ../common/boot.nix
    ./disks.nix
    ./network.nix
  ];

  networking.hostName = "xdash1";

  boot.supportedFilesystems = [
    "vfat"
    "ext4"
  ];

  environment.systemPackages = with pkgs; [
    labwc
    firefox
  ];

  users.users.xdash1 = {
    isNormalUser = true;
    description = "Dashboard Kiosk User";
    extraGroups = [ "video" ];
    home = "/home/xdash1";
  };

  hardware.graphics.enable = true;
  services.xserver.enable = false;

  services.cage = {
    enable = true;
    user = "xdash1";
    program = "${pkgs.firefox}/bin/firefox -kiosk -private-window https://hass.xrs444.net";
  };

  services.getty.autologinUser = "xdash1";

  nixpkgs.config.allowUnfree = true;
  # sops.secrets."wireless-secrets" removed (was wan-wifi.yaml, now split or unused)
}

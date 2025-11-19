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
    ../common/hardware-orangepi.nix
    ../common/boot.nix
    ./network.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    # Only import letsencrypt if not minimal
    (lib.optional (!config.minimalImage) ../../../modules/services/letsencrypt)
    # Add other heavy modules here as needed
  ];

  networking.hostName = hostname;

  # Explicitly disable ZFS for ARM board
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" "xfs" ];

  environment.systemPackages = with pkgs; [
    labwc
    firefox
  ];

  # Define the kiosk user
  users.users.xdash1 = {
    isNormalUser = true;
    description = "Dashboard Kiosk User";
    extraGroups = [ "video" ];
    home = "/home/xdash1";
  };

  # Enable graphics
  hardware.graphics.enable = true;
  
  # Disable X server
  services.xserver.enable = false;

  # Cage kiosk mode
  services.cage = {
    enable = true;
    user = "xdash1";
    program = "${pkgs.firefox}/bin/firefox -kiosk -private-window https://hass.xrs444.net";
  };

  # Auto-login for kiosk
  services.getty.autologinUser = "xdash1";

  # SD image configuration
  sdImage = {
    compressImage = false;  # Set to true if you want .img.zst
    expandOnBoot = true;    # Auto-expand to fill SD card
  };
}


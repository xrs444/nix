# Summary: Minimal SD image configuration for cmrpi1, bootstraps with comin for full config deployment.
{
  pkgs,
  lib,
  stateVersion,
  hostname,
  username,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/hardware/RaspberryPi5
    ../common/boot.nix
    ../../../modules/sdImage/custom.nix
  ];

  system.stateVersion = stateVersion;
  networking.hostName = hostname;

  # Basic user configuration
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = lib.mkDefault pkgs.bash;
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Bootloader configuration for Raspberry Pi 5
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Boot configuration handled by sd-image.nix and hardware modules
}
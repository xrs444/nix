# Summary: Minimal installer configuration for xdash-k, bootstraps with comin for full config deployment.
{
  pkgs,
  lib,
  stateVersion,
  hostname,
  username,
  inputs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-3
    ../common/boot.nix
    ../../../modules/sdImage/custom.nix
  ];

  system.stateVersion = stateVersion;
  networking.hostName = hostname;

  # Enable WiFi for Surface Pro 3 kiosk
  networking.networkmanager.enable = true;

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

  # Minimal boot configuration for x86_64
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  boot.supportedFilesystems = [
    "vfat"
    "ext4"
  ];
}

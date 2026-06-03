# Summary: NixOS ARM host configuration for cmrpi1 - Raspberry Pi 5 running AdGuard DNS
{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/hardware/RaspberryPi5
    ../common/boot.nix
    ./disks.nix
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  # Bootloader configuration for Raspberry Pi 5
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi5 kernel
  boot.initrd.includeDefaultModules = false;

  # RPi5 kernel modules
  boot.initrd.availableKernelModules = lib.mkForce [
    "nvme"
    "usbhid"
    "usb-storage"
    "mmc_block"
    "ext4"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Force the system to use the correct profile path
  system.activationScripts.fixProfile = lib.stringAfter [ "users" ] ''
    rm -f /nix/var/nix/profiles/system
    ln -sf /nix/var/nix/profiles/system-profiles/cmrpi1 /nix/var/nix/profiles/system
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    tmux
  ];

  nixpkgs.config.allowUnfree = true;

  # Open firewall ports for AdGuard Home
  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS
      3000 # AdGuard Home Web UI
    ];
    allowedUDPPorts = [
      53 # DNS
    ];
  };
}
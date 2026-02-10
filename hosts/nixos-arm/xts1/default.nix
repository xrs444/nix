# Summary: NixOS ARM host configuration for xts1, imports boot, hardware, and Raspberry Pi modules.
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
    ../common/hardware-rpi.nix
    ../../../modules/hardware/RaspberryPi4
    #    ./network.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  networking.hostName = hostname;

  # Bootloader configuration for Raspberry Pi
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi4 kernel
  boot.initrd.includeDefaultModules = false;

  # Filter out modules that don't exist in the RPi4 kernel (renamed/removed in 6.12)
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb-storage"
    "vc4"
    "pcie-brcmstb"
    "reset-raspberrypi"
    "sdhci_pci"
    "mmc_block"
    "ext4"
    "nvme"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Force the system to use the correct profile path
  system.activationScripts.fixProfile = lib.stringAfter [ "users" ] ''
    rm -f /nix/var/nix/profiles/system
    ln -sf /nix/var/nix/profiles/system-profiles/xts1 /nix/var/nix/profiles/system
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  hardware.i2c.enable = true;
  nixpkgs.config.allowUnfree = true;
}

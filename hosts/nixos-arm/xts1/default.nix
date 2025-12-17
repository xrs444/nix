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
    ../common/boot.nix
    ../common/performance.nix
    ../common/hardware-rpi.nix
    ../../../modules/hardware/RaspberryPi4
    #    ./network.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  networking.hostName = hostname;

  # Bootloader configuration for Raspberry Pi
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

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

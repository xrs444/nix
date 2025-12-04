{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/boot.nix
    ../common/hardware-rpi.nix
    #    ./network.nix
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

  # hardware config now provided by ../common/hardware-rpi.nix

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  hardware.i2c.enable = true;
  nixpkgs.config.allowUnfree = true;
}

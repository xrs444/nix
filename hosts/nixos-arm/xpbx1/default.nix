# Summary: NixOS ARM host configuration for xpbx1 - Raspberry Pi 3B running Asterisk PBX
# Provisioning: TFTP server serves device configs by MAC address (DHCP option 66 → xpbx1)
# Replace MAC_* placeholders below with actual device MAC addresses (uppercase, no separators for
# Grandstream; lowercase no separators for Polycom; lowercase with colons for Sangoma).
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
    ../../../modules/hardware/RaspberryPi4 # Pi3B is similar to Pi4
    ../common/boot.nix
    ./disks.nix
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  # Disable only device tree overlays to avoid Python libfdt issue
  # Keep deviceTree enabled but clear overlays to bypass the broken builder
  hardware.deviceTree.overlays = lib.mkForce [];

  # Bootloader configuration for Raspberry Pi 3B
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi kernel
  boot.initrd.includeDefaultModules = false;

  # RPi3B kernel modules
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb-storage"
    "mmc_block"
    "ext4"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Pi3B (39-bit VA) kernel rejects NixOS's hardening default of 33 for vm.mmap_rnd_bits.
  # CONFIG_ARCH_MMAP_RND_BITS_MAX is lower on Pi3 than Pi4 (48-bit VA). Use 18 (kernel default).
  boot.kernel.sysctl."vm.mmap_rnd_bits" = lib.mkForce 18;

  # Force the system to use the correct profile path
  system.activationScripts.fixProfile = lib.stringAfter [ "users" ] ''
    rm -f /nix/var/nix/profiles/system
    ln -sf /nix/var/nix/profiles/system-profiles/xpbx1 /nix/var/nix/profiles/system
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    tmux
  ];

  nixpkgs.config.allowUnfree = true;
}

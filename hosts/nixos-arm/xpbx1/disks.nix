# Summary: Disk configuration for xpbx1 - SD card for Raspberry Pi 3B
{ lib, ... }:

{
  # Filesystem configuration for SD card boot
  # Raspberry Pi 3B will boot from SD card
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
  };

  # Swap file configuration (optional, useful for Pi3B with limited RAM)
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB swap
    }
  ];
}

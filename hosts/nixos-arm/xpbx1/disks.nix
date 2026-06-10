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

  # No swap — running swap on SD card causes I/O hangs and burns write cycles.
  # Pi3B has 1GB RAM; if memory pressure becomes a problem, use a USB drive instead.
  swapDevices = [ ];
}

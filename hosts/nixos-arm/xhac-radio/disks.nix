{ config, ... }:
{
  # Minimal stub: define root filesystem for xhac-radio
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
}

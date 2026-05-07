# Summary: Disk configuration for cmrpi1 - 256GB SSD via NVMe
{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        # Placeholder - update with actual device ID after installation
        # Find with: ls -la /dev/disk/by-id/
        device = "/dev/disk/by-id/nvme-PLACEHOLDER";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };

  # Fallback filesystem configuration for initial SD card boot
  # Note: Comment out disko.devices above and uncomment this for SD card deployment
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = "ext4";
  # };
}
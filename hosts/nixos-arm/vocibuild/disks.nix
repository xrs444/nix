# Disko disk layout for vocibuild — Oracle Cloud A1 Flex VM.
# Oracle Cloud paravirtualized block volumes appear as /dev/sda.
# Verify with: lsblk   (run on Oracle Linux before nixos-anywhere wipes the disk)
# If the device is /dev/vda or /dev/nvme0n1, change `device` below before running nixos-anywhere.
{ ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "512M";
          type = "EF00";
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
}

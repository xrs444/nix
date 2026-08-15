{
  # PLACEHOLDER — replace with xsvr4's actual boot NVMe by-id path once the hardware is
  # installed (ls -la /dev/disk/by-id/ | grep nvme on xsvr4). Layout mirrors xsvr3.
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-REPLACE_ME_BOOT_DISK";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1000M";
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
                format = "xfs";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}

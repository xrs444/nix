# ata-CT1000BX500SSD1_2432E8BE03BE - System
# ata-CT1000BX500SSD1_2434E9882FC2 - System
# ata-CT1000MX500SSD1_2410E89C985C - Longhorn
{
  disko.devices = {
    disk = {
      one = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT1000BX500SSD1_2432E8BE03BE";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1024M";
              type = "EF00";
            };
            mdadm = {
              size = "100%";
            };
          };
        };
      };
      two = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FC2";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1024M";
              type = "EF00";
            };
            mdadm = {
              size = "100%";
            };
          };
        };
      };
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        devices = [
          "/dev/disk/by-id/ata-CT1000BX500SSD1_2432E8BE03BE-part1" # ESP on disk one
          "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FC2-part1" # ESP on disk two
        ];
        content = {
          type = "filesystem";
          format = "vfat";
          mountOptions = [
            "defaults"
            "umask=0077"
          ];
          mountpoint = "/boot";
        };
      };
      root_fs = {
        type = "mdadm";
        level = 1;
        devices = [
          "/dev/disk/by-id/ata-CT1000BX500SSD1_2432E8BE03BE-part2" # mdadm partition on disk one
          "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FC2-part2" # mdadm partition on disk two
        ];
        content = {
          type = "filesystem";
          format = "xfs";
          mountpoint = "/";
        };
      };
    };
  };
}

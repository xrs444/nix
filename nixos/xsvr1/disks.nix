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
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            mdadm = {
              size = "100%";
              type = "FD00";
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
              content = {
                type = "filesystem";
                format = "vfat";
              };
            };
            mdadm = {
              size = "100%";
              type = "FD00";
            };
          };
        };
      };
    };
    mdadm = {
      root_fs = {
        type = "mdadm";
        level = 1;
        devices = [
          "/dev/disk/by-id/ata-CT1000BX500SSD1_2432E8BE03BE-part2"
          "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FC2-part2"
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

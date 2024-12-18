# ata-CT1000BX500SSD1_2434E9882FCF - System
# ata-CT1000BX500SSD1_2434E988331E - System
#
{
  disko.devices = {
    disk = {
      one = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FCF";
        content = {
          type = "gpt";
          partitions = {
#            BOOT = {
#              size = "1M";
#              type = "EF02"; # for grub MBR
#            };
            ESP = {
              size = "1024";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "root_fs";
              };
            };
          };
        };
      };
      two = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E988331E";
        content = {
          type = "gpt";
          partitions = {
#            BOOT = {
#              size = "1M";
#              type = "EF02"; # for grub MBR
#            };
            ESP = {
              size = "1024M";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "root_fs";
              };
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
        content = {
          type = "gpt";
          partitions.primary = {
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
}
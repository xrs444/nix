# ata-CT1000BX500SSD1_2432E8BE03BE - System
# ata-CT1000BX500SSD1_2434E9882FC2 - System
# ata-CT1000MX500SSD1_2410E89C985C - Longhorn

{ lib, ... }:

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
        device = "/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FC2";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1024M";
              content = {
                type = "filesystem";
                format = "vfat";
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

# nvme-CT500P3PSSD8_241748806E5C - System
# nvme-CT1000P3SSD8_24414B6FE363 - Longhorn
#

{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-CT500P3PSSD8_241748806E5C";
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

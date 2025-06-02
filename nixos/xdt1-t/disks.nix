# - System
# - Scratch

{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/ata-CT1000MX500SSD1_2339E87A35BC";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "4000M";
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

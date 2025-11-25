{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/ata-SAMSUNG_SSD_830_Series_S0XXNEAC706979";
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
  fileSystems."/" = {
    device = lib.mkForce "/dev/sda";
    fsType = lib.mkForce "xfs";
  };
}
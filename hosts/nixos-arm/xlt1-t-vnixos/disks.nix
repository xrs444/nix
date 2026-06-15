{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/virtio-49C10A30F1F0406CB59B";
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
    device = lib.mkForce "/dev/disk/by-uuid/2cd1bf1f-b177-4056-974d-18ebf4991e10";
    fsType = lib.mkForce "xfs";
  };
}

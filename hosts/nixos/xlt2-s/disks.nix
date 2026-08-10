{
  # Single-drive layout. Device confirmed from installer 2026-08-09.
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLQ512HBLU-00BH1_S671NJ3T389723";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "2000M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" "noauto" "x-systemd.automount" ];
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
    };
  };
}

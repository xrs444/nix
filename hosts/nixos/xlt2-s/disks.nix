{
  # Single-drive layout. Replace `main.device` with the actual
  # /dev/disk/by-id/... path once confirmed from the installer.
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/CHANGEME";
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

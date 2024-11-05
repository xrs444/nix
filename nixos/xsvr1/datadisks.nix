#
#
#
#
#
#
{
  disko.devices = {
    disk = {
      data-one = {
        type = "disk";
        device = "/dev/disk/by-id/ata-";
        content = {
          type ="gpt";
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "";
            };
          };
        };
      };
    };

    disk = {
      data-two = {
        type = "disk";
        device = "/dev/disk/by-id/ata-";
        content = {
          type ="gpt";
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "";
            };
          };
        };
      };
    };

    disk = {
      data-three = {
        type = "disk";
        device = "/dev/disk/by-id/ata-";
        content = {
          type ="gpt";
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "";
            };
          };
        };
      };
    };

    disk = {
      data-four = {
        type = "disk";
        device = "/dev/disk/by-id/ata-";
        content = {
          type ="gpt";
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "";
            };
          };
        };
      };
    };

    disk = {
      data-five = {
        type = "disk";
        device = "/dev/disk/by-id/ata-";
        content = {
          type ="gpt";
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "";
            };
          };
        };
      };
    };

    disk = {
      data-six = {
        type = "disk";
        device = "/dev/disk/by-id/ata-";
        content = {
          type ="gpt";
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "";
            };
          };
        };
      };
    };

    zpool = {
     tank = { 
        type = "zpool";
        mode = "raidz2";
        options.cachefile = "none";
        rootFSOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
      };
      mountpoint = "/zfs";
      postCreateHook = 

      datasets = {
        zfs_fs = {
          mountpoint = /zfs/media;
          options."com.sun:auto-snapshot" = "true";
        };
        zfs_fs = {
          mountpoint = /zfs/containers;
          options."com.sun:auto-snapshot" = "true";
        };
        zfs_fs = {
          mountpoint = /zfs/googlebackups;
          options."com.sun:auto-snapshot" = "true";
        };
        zfs_fs = {
          mountpoint = /zfs/clientbackups;
          options."com.sun:auto-snapshot" = "true";
        };





      };

    };
  };
}
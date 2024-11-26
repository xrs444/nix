# ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0791190 - VDEV 1 - 1
# ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0774016 - VDEV 1 - 2
# ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0771782 - VDEV 2 - 1
# ata-WDC_WD30EFRX-68EUZN0_WD-WMC4N2432718 - VDEV 2 - 2
# ata-WDC_WD30EFRX-68EUZN0_WD-WMC4N2449151 - VDEV 3 - 1
# ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0753744 - VDEV 3 - 2
{
  disko.devices = {
    disk = {
      data-one = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0791190";
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
        device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0774016";
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
        device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0771782";
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
        device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WMC4N2432718";
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
        device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WMC4N2449151";
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
        device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0753744";
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

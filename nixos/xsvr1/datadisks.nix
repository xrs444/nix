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
              pool = "zroot";
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
              pool = "zroot";
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
              pool = "zroot";
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
              pool = "zroot";
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
              pool = "zroot";
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
              pool = "zroot";
            };
          };
        };
      };
    };

    zpool = {
     zroot = { 
        type = "zpool";
        mode = {
          topology = {
            type = topology;
            vdev =[
              { 
                mode = mirror;
                members = [ "data-one" "data-two"];
              }
            ];
             vdev =[
              { 
                mode = mirror;
                members = [ "data-three" "data-four"];
              }
            ];
            vdev =[
              { 
                mode = mirror;
                members = [ "data-five" "data-six"];
              }
            ];
          };
        };
        options.cachefile = "none";
        rootFSOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };
      };
      mountpoint = "/zfs";

      datasets = {
        media = {
          type = "zfs_fs";
          mountpoint = /zfs/media;
          options."com.sun:auto-snapshot" = "true";
        };
        containers = {
          type = "zfs_fs";
          mountpoint = /zfs/containers;
          options."com.sun:auto-snapshot" = "true";
        };
        googlebackups = {
          type = "zfs_fs";
          mountpoint = /zfs/googlebackups;
          options."com.sun:auto-snapshot" = "true";
        };
        clientbackups = {
          type = "zfs_fs";
          mountpoint = /zfs/clientbackups;
          options."com.sun:auto-snapshot" = "true";
        };
      };
    };
  };
}

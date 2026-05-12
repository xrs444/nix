{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/by-id/mmc-SR128_0xeec59d30";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # Raw reservation for U-Boot. Amlogic boot ROM reads U-Boot from the
            # first sectors of the disk (written by dd, outside any filesystem).
            # EF02 marks this space as in-use so disko/parted won't allocate it.
            uboot = {
              size = "8M";
              type = "EF02";
            };
            # Separate ext4 /boot so U-Boot can read extlinux.conf.
            # U-Boot (ubootLibreTechCC) does not support XFS; without this
            # partition it finds 0 bootflows and fails to boot the XFS root.
            boot = {
              size = "512M";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
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

  # Part layout: uboot=part1 (EF02), boot=part2 (ext4), root=part3 (xfs).
  # mkForce overrides sd-image.nix's label-based ext4 defaults.
  fileSystems."/boot" = {
    device = lib.mkForce "/dev/by-id/mmc-SR128_0xeec59d30-part2";
    fsType = lib.mkForce "ext4";
  };

  fileSystems."/" = {
    device = lib.mkForce "/dev/by-id/mmc-SR128_0xeec59d30-part3";
    fsType = lib.mkForce "xfs";
  };
}

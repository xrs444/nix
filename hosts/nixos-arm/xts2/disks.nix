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

  # Override sd-image.nix's default fileSystems."/" (ext4, label-based) so the
  # full deployed config uses the correct partition and filesystem type.
  # Without mkForce here, sd-image.nix wins and the fsType conflict is fatal.
  # Root is -part2: uboot (EF02) is -part1.
  fileSystems."/" = {
    device = lib.mkForce "/dev/by-id/mmc-SR128_0xeec59d30-part2";
    fsType = lib.mkForce "xfs";
  };
}

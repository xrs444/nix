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
            # ext4 root so U-Boot (ubootLibreTechCC) can read extlinux.conf
            # directly. U-Boot does not support XFS; ext4 avoids needing a
            # separate /boot partition.
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

  # Root is part2 (uboot EF02 is part1).
  # mkForce overrides sd-image.nix's label-based defaults.
  fileSystems."/" = {
    device = lib.mkForce "/dev/by-id/mmc-SR128_0xeec59d30-part2";
    fsType = lib.mkForce "ext4";
  };
}

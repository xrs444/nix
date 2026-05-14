{ lib, ... }:

{
  # Board now boots via UEFI from SPI flash (LibreTech firmware).
  # Layout: EFI system partition + ext4 root. No U-Boot reservation needed.
  disko.devices = {
    disk = {
      main = {
        device = "/dev/by-id/mmc-SR128_0xeec59d30";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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

  # lib/default.nix imports sd-image.nix for all ARM disko hosts, which sets
  # fileSystems."/" to NIXOS_SD label. mkForce here wins over that default.
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-partlabel/disk-main-esp";
    fsType = "vfat";
  };
}

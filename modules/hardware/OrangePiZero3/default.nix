# Summary: Hardware configuration for Orange Pi Zero 3, sets bootloader and system options for Allwinner H618 SoC.
# Orange Pi Zero 3 hardware configuration
# Uses Allwinner H618 SoC
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Orange Pi Zero 3 specific boot configuration
  boot = {
    loader = {
      # Explicitly disable GRUB for ARM boards
      grub.enable = lib.mkForce false;

      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;

      # Use the generic extlinux compatible loader
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };

    # Use mainline kernel for Orange Pi Zero 3 (Allwinner H618)
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Orange Pi Zero 3 specific kernel modules
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "sunxi_wdt"
      "sun50i_codec_analog"
      "sun8i_codec"
      "sun4i_i2s"
      # Note: sun8i_emac may not be available in mainline kernel 6.18
      # Network should work with dwmac-sun8i instead
    ];

    # Kernel parameters for Orange Pi Zero 3
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
      "earlycon=uart,mmio32,0x05000000"
      "root=/dev/disk/by-label/NIXOS_SD"
      "rootfstype=ext4"
      "rootwait"
    ];
  };

  # Root filesystem configuration (can be overridden by disko)
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # Boot partition (can be overridden by disko)
  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # Power management for ARM SoC
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Hardware support
  hardware = {
    enableRedistributableFirmware = true;
    # Enable device tree overlays
    deviceTree.enable = lib.mkDefault true;
  };

  # Write U-Boot to SD image at the Allwinner-required 8KiB offset (sector 16).
  # Without this the board falls back to factory SPI NOR flash bootloader,
  # which prints "fail to mount /dev/mtdblock4" trying to access its env partition.
  sdImage.postBuildCommands = ''
    dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

  # Network interface for Orange Pi Zero 3
  networking.interfaces.end0.useDHCP = lib.mkDefault true;
}

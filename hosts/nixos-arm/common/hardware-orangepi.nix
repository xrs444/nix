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
      "sun8i_emac"
    ];
    
    # Kernel parameters for Orange Pi Zero 3
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
      "earlycon=uart,mmio32,0x05000000"
    ];
  };

  # Root filesystem configuration (can be overridden by disko)
  # fileSystems."/" = lib.mkDefault {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = "ext4";
  #   options = [ "noatime" ];
  # };

  # Boot partition (can be overridden by disko)
  # fileSystems."/boot" = lib.mkDefault {
  #   device = "/dev/disk/by-label/FIRMWARE";
  #   fsType = "vfat";
  #   options = [ "fmask=0022" "dmask=0022" ];
  # };
  
  # Power management for ARM SoC
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Hardware support
  hardware = {
    enableRedistributableFirmware = true;
    # Enable device tree overlays
    deviceTree.enable = lib.mkDefault true;
  };

  # Network interface for Orange Pi Zero 3
  networking.interfaces.end0.useDHCP = lib.mkDefault true;
}
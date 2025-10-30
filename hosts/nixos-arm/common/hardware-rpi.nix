# Raspberry Pi hardware configuration
# Suitable for Raspberry Pi 4 and later models
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Raspberry Pi specific boot configuration
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
      
      # Use the generic extlinux compatible loader
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };
    
    # Raspberry Pi firmware
    kernelPackages = lib.mkDefault pkgs.linuxPackages_rpi4;
    
    # Enable GPU firmware
    loader.raspberryPi = {
      enable = lib.mkDefault true;
      version = lib.mkDefault 4;
      firmwareConfig = ''
        # Enable 64-bit mode
        arm_64bit=1
        
        # GPU memory split (adjust based on use case)
        gpu_mem=128
        
        # Enable UART for serial console
        enable_uart=1
      '';
    };
    
    # Raspberry Pi specific kernel modules
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb"
      "bcm2835_dma"
      "i2c_bcm2835"
      "spi_bcm2835"
    ];
    
    # Enable hardware-specific features
    kernelParams = [
      "console=ttyS1,115200n8"
      "console=tty0"
    ];
  };
  
  # Power management for Raspberry Pi
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
# ARM64 server/workstation hardware configuration
# Suitable for ARM64 servers and high-end SBCs with UEFI support
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # UEFI-capable ARM64 systems
  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    
    # Use mainline kernel for better hardware support
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    
    # Common ARM64 server kernel modules
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sdhci"
      "sdhci_pci"
      "mmc_block"
    ];
    
    # Kernel parameters for ARM64 servers
    kernelParams = [
      "console=tty0"
      "console=ttyAMA0,115200"
    ];
  };
  
  # Enable hardware features common to ARM64 servers
  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    enableAllFirmware = lib.mkDefault true;
  };
  
  # Performance settings for server workloads
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  
  # Networking optimizations for servers
  boot.kernel.sysctl = {
    "net.core.rmem_max" = lib.mkDefault 268435456;
    "net.core.wmem_max" = lib.mkDefault 268435456;
    "net.ipv4.tcp_rmem" = lib.mkDefault "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = lib.mkDefault "4096 65536 134217728";
  };
}
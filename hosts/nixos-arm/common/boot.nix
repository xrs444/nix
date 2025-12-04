# Common boot configuration for NixOS ARM hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      # Many ARM systems use U-Boot or similar, but some can use systemd-boot
      # Use lower priority so hardware-specific configs can override
      systemd-boot.enable = lib.mkOverride 1500 false;
      efi.canTouchEfiVariables = lib.mkOverride 1500 false;

      # For systems that do support UEFI (like some ARM64 servers/SBCs)
      grub = {
        enable = lib.mkDefault false;
        efiSupport = lib.mkDefault true;
      };
    };

    # Common kernel modules for ARM systems
    initrd.availableKernelModules = lib.mkDefault [
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sdhci"
      "mmc_block"
      "nvme"
    ];

    # ARM systems often benefit from these kernel parameters
    kernelParams = lib.mkDefault [
      "console=tty0"
    ];
  };
}

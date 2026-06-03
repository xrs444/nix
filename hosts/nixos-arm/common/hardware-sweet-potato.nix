# Hardware configuration for Libre Computer AML-S905X-CC-V2 "Sweet Potato"
# Amlogic S905X SoC — boots via UEFI firmware stored in onboard SPI flash.
# LibreTech provides UEFI firmware at boot.libre.computer/release/aml-s905x-cc-v2/
# Flash spiflash.img to SD, boot once to write UEFI to SPI, then boot from eMMC.
{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      # Board boots UEFI from SPI flash; EFI vars not writable on this platform.
      systemd-boot.enable = lib.mkForce true;
      efi.canTouchEfiVariables = lib.mkForce false;
      grub.enable = lib.mkForce false;
      generic-extlinux-compatible.enable = lib.mkForce false;
    };

    # Amlogic serial console
    kernelParams = lib.mkForce [
      "console=ttyAML0,115200n8"
      "console=tty0"
    ];

    # meson_gx_mmc drives the Amlogic SD/eMMC host controller
    initrd.availableKernelModules = [
      "meson_gx_mmc"
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sdhci"
      "mmc_block"
    ];

    # Mainline kernel has solid Amlogic GXL support
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # SBC thermals — ondemand is friendlier than performance
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}

# Hardware configuration for Libre Computer AML-S905X-CC2 "Sweet Potato"
# Amlogic S905X2 SoC — no UEFI, boots via U-Boot + extlinux
{
  lib,
  pkgs,
  ...
}:
let
  # ubootLibreTechCC is marked broken in the current nixpkgs pin. Clear the
  # flag locally — the binary works fine for the AML-S905X-CC / CC2 platform.
  uboot = pkgs.ubootLibreTechCC.overrideAttrs (o: {
    meta = o.meta // { broken = false; };
  });
in
{
  # Amlogic has no UEFI. Override the mkDefault values from hardware-arm64-server.nix
  # (mkDefault = mkOverride 1000; mkForce = mkOverride 50, so these win).
  boot = {
    loader = {
      grub.enable = lib.mkForce false;
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
      # U-Boot reads /boot/extlinux/extlinux.conf at startup
      generic-extlinux-compatible.enable = lib.mkForce true;
    };

    # Amlogic serial is ttyAML0, not ttyAMA0 (BCM/RPi)
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

    # Mainline kernel has solid Amlogic GXL/G12 support
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  # Embed U-Boot into the SD image at the offsets the Amlogic boot ROM expects.
  # ubootLibreTechCC targets the AML-S905X-CC (Le Potato); the CC2 (Sweet Potato)
  # shares the same Amlogic GXL platform and boots with the same binary.
  # Two dd passes are required: one for the main body (sector 1+), one for the
  # 444-byte header at sector 0 that the boot ROM reads first.
  sdImage.postBuildCommands = ''
    dd if=${uboot}/u-boot.gxl.sd.bin \
       of=$img conv=fsync,notrunc bs=512 skip=1 seek=1
    dd if=${uboot}/u-boot.gxl.sd.bin \
       of=$img conv=fsync,notrunc bs=1 count=444
  '';

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # SBC thermals — ondemand is friendlier than performance
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}

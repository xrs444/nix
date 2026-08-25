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

      # canTouchEfiVariables=false makes the installer pass bootctl
      # --no-variables, but confirmed 2026-08-24 that alone isn't enough:
      # `bootctl ... update` (as opposed to `install`) still attempted to
      # write an EFI Boot NVRAM entry and hard-failed with "Read-only file
      # system" on this board's SPI-flash UEFI firmware, which deploy-rs's
      # magic-rollback correctly caught and reverted. --graceful is the
      # option that actually makes bootctl tolerate that failure instead of
      # erroring — nixpkgs' own option description says only to use it when
      # systemd-boot otherwise fails to install, which is exactly this case.
      systemd-boot.graceful = lib.mkForce true;
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

  # nixos-configuration-reference-manpage renders docs for the entire merged
  # option tree, including this flake's own custom modules — it's unique to
  # this repo's module set and can never be substituted from cache.nixos.org,
  # so every host must build it from scratch at least once regardless of how
  # trivial its own config is. Confirmed 2026-08-24: building it locally on
  # xidm1 (this board, 2GB RAM) SIGKILLed nixos-rebuild — an OOM kill, not a
  # transient error. CI never hit this because it delegates ARM builds to
  # vocibuild (much larger) and only copies the result here; it only bites a
  # build actually run ON this hardware. Same fix already applied to sdImage
  # hosts in modules/sdImage/custom.nix for the identical reason.
  documentation.nixos.enable = lib.mkDefault false;
}

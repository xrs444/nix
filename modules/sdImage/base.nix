# Summary: Base SD image module that configures ARM boards to boot from SD card.
# SD card boot requires extlinux bootloader, not UEFI/systemd-boot.
{
  config,
  lib,
  ...
}:
{
  imports = [ ];

  # SD card images must use extlinux bootloader
  boot.loader = {
    grub.enable = lib.mkForce false;
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    generic-extlinux-compatible.enable = lib.mkDefault true;
  };

  # Console configuration for ARM boards
  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelParams = lib.mkDefault [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
  ];

  # Populate the root filesystem with bootloader configuration
  sdImage.populateRootCommands = ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
  '';

  # Populate firmware partition (empty by default, hardware modules can override)
  sdImage.populateFirmwareCommands = lib.mkDefault "";
}

# Summary: NixOS ARM host configuration for xts1, imports boot, hardware, and Raspberry Pi modules.
{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-rpi.nix
    ../../../modules/hardware/RaspberryPi4
    #    ./network.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  networking.hostName = hostname;

  # Bootloader configuration for Raspberry Pi
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi4 kernel
  boot.initrd.includeDefaultModules = false;

  # Filter out modules that don't exist in the RPi4 kernel (renamed/removed in 6.12)
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb-storage"
    "vc4"
    "pcie-brcmstb"
    "reset-raspberrypi"
    "sdhci_pci"
    "mmc_block"
    "ext4"
    "nvme"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Force the system to use the correct profile path
  system.activationScripts.fixProfile = lib.stringAfter [ "users" ] ''
    rm -f /nix/var/nix/profiles/system
    ln -sf /nix/var/nix/profiles/system-profiles/xts1 /nix/var/nix/profiles/system
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  hardware.i2c.enable = true;
  hardware.raspberry-pi."4".poe-plus-hat.enable = true;
  nixpkgs.config.allowUnfree = true;

  # RPi4 SD image firmware configuration
  sdImage.populateFirmwareCommands = let
    configTxt = pkgs.writeText "config.txt" ''
      [pi4]
      kernel=u-boot-rpi4.bin
      enable_gic=1
      armstub=armstub8-gic.bin
      disable_overscan=1

      [cm4]
      otg_mode=1

      [all]
      arm_64bit=1
      enable_uart=1
      avoid_warnings=1
    '';
  in ''
    (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)

    # Device tree files required by the RPi4 GPU firmware
    cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/
    cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-400.dtb firmware/
    cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4.dtb firmware/
    cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4s.dtb firmware/
    cp -r ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays firmware/

    cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
    cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
    cp ${configTxt} firmware/config.txt
  '';
}

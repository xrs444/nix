# Summary: Minimal SD image configuration for xts1, bootstraps with comin for full config deployment.
{
  pkgs,
  lib,
  stateVersion,
  hostname,
  username,
  ...
}:
let
  disksPath = ./disks.nix;
  hasDisksConfig = builtins.pathExists disksPath;
in
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-rpi.nix
    ../common/boot.nix
    ../../../modules/sdImage/custom.nix
  ]
  ++ lib.optional hasDisksConfig disksPath;
  system.stateVersion = stateVersion;
  networking.hostName = hostname;

  # Basic user configuration
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = lib.mkDefault pkgs.bash;
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Disable verbose console output for headless operation
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
  ];

  # Disable console on tty1 to prevent log spam
  console.enable = lib.mkDefault false;

  # Boot configuration handled by sd-image.nix and hardware modules

  # RPi4 SD image firmware configuration
  sdImage.populateFirmwareCommands =
    let
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
    in
    ''
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

# Summary: Minimal SD card image configuration for xpbx1 initial deployment
{
  pkgs,
  hostname,
  inputs,
  ...
}:
{
  imports = [
    inputs.comin.nixosModules.comin
    ../../../modules/hardware/RaspberryPi4 # Pi3B is similar to Pi4
    ./disks.nix
    ./network.nix
  ];

  networking.hostName = hostname;

  # Enable nix flakes and commands for comin
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Disable only device tree overlays to avoid Python libfdt issue
  # Keep deviceTree enabled but clear overlays to bypass the broken builder
  hardware.deviceTree.overlays = pkgs.lib.mkForce [];

  # Allow missing kernel modules during SD image build
  # The default SD image config includes modules not in the RPi kernel
  boot.initrd.allowMissingModules = true;

  # Enable SSH for initial setup
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set a default root password for initial setup
  # CHANGE THIS AFTER FIRST BOOT
  users.users.root.initialPassword = "nixos";

  # Enable comin for automatic configuration deployment
  services.comin = {
    enable = true;
    hostname = hostname;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/xrs444/nix.git";
        branches.main.name = "main";
      }
    ];
  };

  # Ensure comin restarts on failure
  systemd.services.comin.serviceConfig = {
    Restart = "always";
    RestartSec = 30;
  };

  # Minimal system packages for initial setup
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    tmux
    curl
    htop
  ];

  # SD image configuration
  sdImage = {
    compressImage = false;
    imageName = "${hostname}-sd-image.img";

    # Expand root partition on first boot
    expandOnBoot = true;

    # Firmware configuration for Raspberry Pi 3B
    firmwareSize = 128; # MB

    # Manually populate firmware to avoid device-tree-overlays Python libfdt issue
    populateFirmwareCommands =
      let
        configTxt = pkgs.writeText "config.txt" ''
          [pi3]
          kernel=u-boot-rpi3.bin

          [all]
          arm_64bit=1
          enable_uart=1
          avoid_warnings=1
        '';
      in
      ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)

        # Device tree files for Raspberry Pi 3B
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-3-b.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-3-b-plus.dtb firmware/
        cp -r ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays firmware/

        cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin
        cp ${configTxt} firmware/config.txt
      '';
  };

  # Bootloader configuration
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Disable some services to speed up boot
  systemd.services.systemd-udev-settle.enable = false;

  nixpkgs.config.allowUnfree = true;
}

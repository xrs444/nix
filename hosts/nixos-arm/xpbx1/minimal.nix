# Summary: Minimal SD card image configuration for xpbx1 initial deployment.
# Bootstrap workflow: flash SD image → boot → deploy .#xpbx1 from xsvr1.
# SSH access via thomas-local key (sdImage/custom.nix injects authorizedKeys).
{
  config,
  pkgs,
  stateVersion,
  hostname,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/hardware/RaspberryPi4 # Pi3B is similar to Pi4
    ../common/boot.nix
    ./disks.nix
    ./network.nix
    ../../../modules/sdImage/custom.nix
  ];

  system.stateVersion = stateVersion;
  networking.hostName = hostname;

  # Disable only device tree overlays to avoid Python libfdt issue
  # Keep deviceTree enabled but clear overlays to bypass the broken builder
  hardware.deviceTree.overlays = pkgs.lib.mkForce [];

  # Allow missing kernel modules during SD image build
  # The default SD image config includes modules not in the RPi kernel
  boot.initrd.allowMissingModules = true;

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
    # Was 128MB — the 2026-08-06 mainline-kernel migration (215ba0c) grew the
    # per-generation footprint to ~77MB (Image+initrd+dtbs), and an atomic switch
    # needs old+new simultaneously, blowing past 128MB entirely (bug-508). 1GB is
    # trivial cost against the 116GB card and avoids revisiting this again even if
    # kernel sizes keep trending up. Only takes effect on the NEXT SD card flash
    # (see hosts/nixos-arm/xpbx1/README.md); does not resize the live card.
    firmwareSize = 1024; # MB

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

        # Device tree files for Raspberry Pi 3B.
        # IMPORTANT: sourced from the mainline kernel's OWN compiled dtbs
        # (config.boot.kernelPackages.kernel), not pkgs.raspberrypifw's downstream
        # firmware blobs. Mainline names this board "bcm2837-rpi-3-b" (the actual
        # SoC part number) while downstream firmware calls the same physical board
        # "bcm2710-rpi-3-b" (a legacy family codename) — same hardware, but the two
        # DTBs have different node structures/bindings, and this kernel's drivers
        # (compiled against upstream DT bindings) don't correctly bind to the
        # downstream-formatted one. Confirmed root cause of bug-508's follow-on:
        # totally dead USB (no keyboard, no network — Pi3B's onboard Ethernet is
        # internally wired through the same USB controller) after the 215ba0c
        # mainline-kernel migration, while still copying the downstream DTB here.
        # Kept under the bcm2710-* filename because VideoCore's board
        # auto-detection looks for that exact name regardless of file content —
        # only the CONTENT needs to match the kernel, not the name on disk.
        cp ${config.boot.kernelPackages.kernel}/dtbs/broadcom/bcm2837-rpi-3-b.dtb firmware/bcm2710-rpi-3-b.dtb
        cp ${config.boot.kernelPackages.kernel}/dtbs/broadcom/bcm2837-rpi-3-b-plus.dtb firmware/bcm2710-rpi-3-b-plus.dtb
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

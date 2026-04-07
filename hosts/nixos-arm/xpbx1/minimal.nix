# Summary: Minimal SD card image configuration for xpbx1 initial deployment
{
  pkgs,
  hostname,
  ...
}:
{
  imports = [
    ../../../modules/hardware/RaspberryPi4 # Pi3B is similar to Pi4
    ./disks.nix
    ./network.nix
  ];

  networking.hostName = hostname;

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

  # Minimal system packages for initial setup
  environment.systemPackages = with pkgs; [
    vim
    wget
    tmux
  ];

  # SD image configuration
  sdImage = {
    compressImage = false;
    imageName = "${hostname}-sd-image.img";

    # Expand root partition on first boot
    expandOnBoot = true;

    # Firmware configuration for Raspberry Pi 3B
    firmwareSize = 128; # MB
  };

  # Bootloader configuration
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Disable some services to speed up boot
  systemd.services.systemd-udev-settle.enable = false;

  nixpkgs.config.allowUnfree = true;
}

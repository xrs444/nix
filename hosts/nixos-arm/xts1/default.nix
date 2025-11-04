{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ../common/boot.nix
    ../common/hardware-rpi.nix
    ./disks.nix
#    ./network.nix
  ];

  # Enable POE HAT fan control
  hardware.raspberry-pi."4".poe-fan = {
    enable = true;
    # Optional: customize temperature thresholds and fan speeds
    # temperature = 60000; # Temperature in millidegrees Celsius to start fan
    # speed = 128; # Fan speed (0-255)
  };
}
# Audio configuration for ARM systems
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # PipeWire audio for ARM systems
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    jack.enable = lib.mkDefault false; # Usually not needed on ARM
  };
  
  # ARM-specific audio hardware support
  boot.kernelModules = lib.mkDefault [
    "snd-bcm2835" # Raspberry Pi audio
    "snd-usb-audio" # USB audio devices
  ];
  
  # Audio group for users
  users.groups.audio = {};
}
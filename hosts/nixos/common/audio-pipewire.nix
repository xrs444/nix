# Common audio configuration using PipeWire
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = lib.mkForce false;
  
  # Enable PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;  # Disabled: requires i686-linux pipewire
    pulse.enable = true;
    package = pkgs.pipewire;
    wireplumber.package = pkgs.wireplumber;
  };
}
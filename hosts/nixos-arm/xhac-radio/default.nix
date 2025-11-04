{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
{
  imports = [
    ../common/hardware-raspberrypi.nix
    ../common/boot.nix
    ./network.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  environment.systemPackages = with pkgs; [
    mpd
    mpc-cli
  ];

  # Enable MPD for internet radio
  services.mpd = {
    enable = true;
    musicDirectory = "/var/lib/mpd/music";
    extraConfig = ''
      audio_output {
        type "alsa"
        name "ALSA Output"
      }
    '';
  };

  # SD image configuration
  sdImage = {
    compressImage = false;
    expandOnBoot = true;
  };
}


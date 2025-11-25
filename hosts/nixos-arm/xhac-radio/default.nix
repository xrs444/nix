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
    ../../base-nixos.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    ../common/boot.nix
    ./network.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  networking.hostName = hostname;

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

  # To build a bootable SD image for this host, run:
  # nix build .#nixosConfigurations.xhac-radio.config.system.build.sdImage
  nixpkgs.config.allowUnfree = true;
}


# Summary: NixOS host configuration for xlt2-s, Samantha's AMD laptop (GNOME desktop, WiFi).
{ ... }:
{
  imports = [
    ../../base-nixos.nix
    ../../../modules/packages-workstation
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./disks.nix
    ./shares.nix
    ./fonts.nix
    ../../common
  ];

  networking.hostName = "xlt2-s";
  nixpkgs.config.allowUnfree = true;
}

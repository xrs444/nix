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

  # Kanidm PAM/NSS login (kanidm-unixd). See nix/modules/services/kanidm/pam-client.nix.
  # samantha and xrs444 are in the xlt2-s-admin Kanidm group (sudo); rowan and
  # greyson are in the plain xlt2-s group (login only). See provision.nix.
  homeprod.kanidm.enablePamLogin = true;
}

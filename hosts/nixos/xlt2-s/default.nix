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

  # Kanidm PAM/NSS login (kanidm-unixd) — DISABLED for now (2026-08-17).
  # Short-username resolution collides with the local `samantha` account that
  # home-manager's flake.nix wiring (user = "samantha") depends on, and the
  # sops-managed vikunja secret is chowned to "samantha" before kanidm-unixd
  # is even up, so it'd resolve to the wrong uid once she logs in via Kanidm.
  # Needs a proper migration (home-manager rewiring + secret ownership fix)
  # before re-enabling. See modules/services/kanidm/pam-client.nix and
  # .wolf/buglog.json bug-634/bug-635.
  homeprod.kanidm.enablePamLogin = false;
}

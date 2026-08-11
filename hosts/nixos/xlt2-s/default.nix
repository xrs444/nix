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
  # bitwarden-desktop (homemanager/users/samantha/default.nix) bundles an EOL
  # Electron that nixpkgs flags insecure by default — without this, eval
  # refuses to build it at all (both via integrated Home Manager and a
  # standalone `home-manager switch`).
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
}

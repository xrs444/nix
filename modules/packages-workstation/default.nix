# Summary: NixOS module for workstation-specific packages, adds custom system packages for desktop environments.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    obs-studio
    google-chrome
  ];
}

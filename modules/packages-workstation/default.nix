# Summary: NixOS module for workstation-specific packages, adds custom system packages for desktop environments.
{ pkgs, lib, ... }:

{
  environment.systemPackages =
    with pkgs;
    lib.optionals stdenv.isLinux [
      obs-studio
      google-chrome
    ];
}

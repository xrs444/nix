# Summary: Home Manager configuration for user 'samantha', sets state version and user environment.
{
  lib,
  pkgs,
  desktop ? null,
  ...
}:
{
  home.stateVersion = "25.05";

  imports = lib.optional (builtins.isString desktop) ../../common/desktop;

  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.vja
    pkgs.vikunja-desktop
  ];
}

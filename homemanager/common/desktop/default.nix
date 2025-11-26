{
  pkgs,
  lib,
  desktop ? null,
  ...
}:
{
  imports = lib.optional (desktop != null) (./. + "/${desktop}");

  programs = {
    mpv.enable = true;
  };

  home.packages = with pkgs; [
    desktop-file-utils
    nerdfonts
  ];

  fonts.fontconfig.enable = true;
}

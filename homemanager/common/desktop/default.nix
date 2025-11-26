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
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.ubuntu
    pkgs.nerd-fonts.space-mono
  ];

  fonts.fontconfig.enable = true;
}

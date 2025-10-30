{ pkgs, desktop, ... }:
{
  imports = [
    (./. + "/${desktop}")

  ];

  programs = {
    mpv.enable = true;
  };

  home.packages = with pkgs; [
    desktop-file-utils
  ];

  #fonts.fontconfig.enable = true;

}

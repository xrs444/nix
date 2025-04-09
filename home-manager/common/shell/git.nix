{ pkgs, ... }:
{
  home.packages = with pkgs; [ gh ];

  programs = {
    git = {
      enable = true;

      userEmail = "xrs444@xrs444.net";
      userName = "Thomas Letherby";



    };
  };
}

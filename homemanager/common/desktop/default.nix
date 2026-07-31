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
  ] ++ lib.optional (!pkgs.stdenv.isDarwin) pkgs.firefox;

  fonts.fontconfig.enable = true;

  # Default browser (Linux only — macOS default-browser handling is separate,
  # since Apple doesn't allow setting it purely declaratively).
  xdg.mimeApps = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}

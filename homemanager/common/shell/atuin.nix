{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    enableFishIntegration = pkgs.stdenv.isLinux;
    enableZshIntegration = true;
    enableBashIntegration = true;
    package = pkgs.unstable.atuin;
    settings = {
      # Sync configuration
      sync_address = "https://atuin.xrs444.net";
      sync_frequency = "5m";
      auto_sync = true;

      # UI/UX settings
      enter_accept = false;
      dialect = "us";

      # Dotfiles disabled
      dotfiles = {
        enabled = false;
      };
    };
  };
}

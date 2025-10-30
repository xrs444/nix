{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.unstable.atuin;
    settings = {
      enter_accept = false;
      dialect = "us";
      dotfiles = {
        enabled = false;
      };
    };
  };
}

# Summary: Home Manager configuration for user 'thomas-local', sets up bash shell and basic packages.
{ pkgs, ... }:
{
  home.stateVersion = "25.05";

  # Import common configurations
  imports = [
    ../../common/shell/atuin.nix
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Simple bashrc to avoid startup issues
    bashrcExtra = ''
      # Basic bash configuration for thomas-local
      export PATH=$PATH:/run/current-system/sw/bin
    '';
  };

  # Disable other shells to avoid conflicts
  programs.fish.enable = false;
  programs.zsh.enable = false;

  # Basic packages for the user
  home.packages = with pkgs; [
    coreutils
    findutils
    direnv
  ];

  # Ensure Home Manager doesn't interfere with system shell
  home.sessionVariables = {
    SHELL = "/run/current-system/sw/bin/bash";
  };

  programs.home-manager.enable = true;
}

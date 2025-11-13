{ pkgs, ... }: {
  
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Thomas Letherby";
      userEmail = "xrs444@xrs444.net";
      ignores = [ ".DS_Store" ];
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "micro";
      };
    };
    fish = {
      enable = true;
    };
    starship.enable = true;
  };

  # Install non-standard fonts
  home.packages = with pkgs; [
    # Nerd Fonts for terminal and coding
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    nerd-fonts.hack
    nerd-fonts.iosevka
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;

  # Set default shell preferences
  home.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "firefox";
  };
}
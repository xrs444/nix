{ pkgs, ... }: {
  
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Thomas Letherby";
      userEmail = "xrs444@xrs444.net";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "micro";
      };
    };
    starship.enable = true;
    fish.enable = true;  # Enable fish shell
  };

  # Set default shell preferences
  home.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "firefox";
  };
}
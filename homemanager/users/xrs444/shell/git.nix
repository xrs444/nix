{ pkgs, ... }:
{
  programs.git = {
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
}

{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    historyLimit = 10000;
    extraConfig = "set -g status-bg colour235";
  };
}

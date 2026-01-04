# Summary: System-wide tmux configuration for all hosts
{ lib, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    terminal = "screen-256color";
    historyLimit = 10000;
    extraConfig = '
      # Enable mouse support
      set -g mouse on
      
      # Custom status bar
      set -g status-bg colour235
      set -g status-fg white
      
      # Set prefix to Ctrl-a (more ergonomic than Ctrl-b)
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix
      
      # Vi mode keys
      setw -g mode-keys vi
      
      # Split panes using | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'"'
      unbind %
    '';
  };
  
  # Ensure tmux is available in system packages
  environment.systemPackages = with pkgs; [ tmux ];
}

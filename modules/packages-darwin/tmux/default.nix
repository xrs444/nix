# Summary: System-wide tmux configuration for Darwin hosts (see packages-nixos/tmux for NixOS).
# nix-darwin's programs.tmux module lacks the clock24/terminal/historyLimit
# options that the NixOS module has, so those are set as raw tmux directives
# in extraConfig instead, keeping behavior identical across platforms.
{ ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g clock-mode-style 24
      set -g default-terminal "screen-256color"
      set -g history-limit 10000

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
      unbind '"'
      unbind %
    '';
  };
}

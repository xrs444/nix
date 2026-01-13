# Summary: Terminal configuration module for all systems, adds GhostTTY terminfo support
{ pkgs, lib, config, ... }:

{
  config = {
    # Add ncurses for terminfo database and tools
    environment.systemPackages = with pkgs; [
      ncurses
    ];

    # Set up GhostTTY terminfo for all users
    # GhostTTY uses xterm-256color as its TERM value
    environment.variables = {
      # Ensure TERMINFO_DIRS includes system terminfo
      TERMINFO_DIRS = lib.mkDefault "/run/current-system/sw/share/terminfo:/usr/share/terminfo";
    };

    # For users, ensure proper fallback behavior
    environment.sessionVariables = {
      # If TERM is not found, fallback to xterm-256color
      TERM = lib.mkDefault "xterm-256color";
    };

    # Install GhostTTY terminfo definition
    # GhostTTY is compatible with xterm-256color, but we can create a specific entry
    environment.etc."terminfo/g/ghostty".source = "${pkgs.ncurses}/share/terminfo/x/xterm-256color";
    environment.etc."terminfo/x/xterm-ghostty".source = "${pkgs.ncurses}/share/terminfo/x/xterm-256color";
  };
}

# Summary: Terminal configuration module for all systems, adds WezTerm terminfo support.
# environment.sessionVariables doesn't exist as an option on nix-darwin, so that part
# lives in packages-nixos/terminal instead of being conditioned here.
{ pkgs, lib, ... }:

{
  config = {
    # Add ncurses for terminfo database and tools
    environment.systemPackages = with pkgs; [
      ncurses
    ];

    # Set up WezTerm terminfo for all users
    # WezTerm uses xterm-256color as its TERM value
    environment.variables = {
      # Ensure TERMINFO_DIRS includes system terminfo
      TERMINFO_DIRS = lib.mkDefault "/run/current-system/sw/share/terminfo:/usr/share/terminfo";
    };

    # Install WezTerm terminfo definition
    # WezTerm is compatible with xterm-256color
    environment.etc."terminfo/w/wezterm".source = "${pkgs.ncurses}/share/terminfo/x/xterm-256color";
  };
}

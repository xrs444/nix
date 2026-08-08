# Summary: Terminal configuration module for all systems, adds WezTerm terminfo support.
# environment.sessionVariables doesn't exist as an option on nix-darwin, so that part
# lives in packages-nixos/terminal instead of being conditioned here.
{ pkgs, lib, ... }:

let
  # "wezterm" terminfo entry, aliased to xterm-256color (WezTerm-compatible).
  # Delivered via systemPackages/share/terminfo — NOT environment.etc:
  # nix-darwin's config/terminfo.nix makes /etc/terminfo a symlink into the
  # read-only store (${system.path}/share/terminfo), so an
  # environment.etc."terminfo/w/..." entry makes the etc builder mkdir
  # through that symlink and fail with "Permission denied" (bug-527, hit on
  # xcog1's first switch). Putting the entry in share/terminfo lands it in
  # the exact tree /etc/terminfo points at, and NixOS finds it via
  # TERMINFO_DIRS below.
  wezterm-terminfo-alias = pkgs.runCommand "wezterm-terminfo-alias" { } ''
    mkdir -p $out/share/terminfo/w
    # This nixpkgs' ncurses stores terminfo under 2-hex-digit hashed dirs
    # (e.g. "78" for 'x', not a literal "x/" subdir) — don't hardcode the
    # layout, find the real file (bug-527, found while fixing the etc-build
    # permission error this hardcoded path silently caused for years: a
    # dangling environment.etc symlink target doesn't fail a build, so
    # nobody noticed xterm-256color was never actually being copied).
    src=$(find ${pkgs.ncurses}/share/terminfo -name xterm-256color -print -quit)
    if [ -z "$src" ]; then
      echo "wezterm-terminfo-alias: xterm-256color not found under ncurses terminfo tree" >&2
      exit 1
    fi
    cp "$src" $out/share/terminfo/w/wezterm
  '';
in
{
  config = {
    # Add ncurses for terminfo database and tools
    environment.systemPackages = with pkgs; [
      ncurses
      wezterm-terminfo-alias
    ];

    # Merge share/terminfo from systemPackages into the system path
    # (nix-darwin's terminfo module already does this on darwin; explicit
    # here so NixOS hosts get it too).
    environment.pathsToLink = [ "/share/terminfo" ];

    # Set up WezTerm terminfo for all users
    # WezTerm uses xterm-256color as its TERM value
    environment.variables = {
      # Ensure TERMINFO_DIRS includes system terminfo
      TERMINFO_DIRS = lib.mkDefault "/run/current-system/sw/share/terminfo:/usr/share/terminfo";
    };
  };
}

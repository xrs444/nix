# Summary: Linux-only complement to packages-common/terminal.
# environment.sessionVariables isn't an option on nix-darwin, so this piece
# is scoped to NixOS hosts only rather than conditioned on pkgs.stdenv.isLinux
# (deciding attribute structure from `pkgs` here would be circular, since this
# flake derives `pkgs` from `config`).
{ lib, ... }:
{
  # For users, ensure proper fallback behavior
  environment.sessionVariables = {
    # If TERM is not found, fallback to xterm-256color
    TERM = lib.mkDefault "xterm-256color";
  };
}

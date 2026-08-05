# Summary: NixOS module for NixOS-specific packages, imports submodules and configures Kanidm server URI.
{ lib, ... }:
{
  imports = [
    ./kanidm/default.nix
    ./tmux/default.nix
    ./terminal/default.nix
  ];
}

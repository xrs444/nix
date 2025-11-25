
# overlays/all.nix
# Exports all overlays as an attribute set for use in flake.nix
{ inputs }:
{
  kanidm = import ./kanidm.nix { inherit inputs; };
  pkgs = import ./pkgs.nix { inherit inputs; };
  unstable = import ./unstable.nix { inherit inputs; };
}


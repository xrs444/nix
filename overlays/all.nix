

# overlays/all.nix
# Exports all overlays as a list for use in flake.nix
{ inputs }:
[
  (import ./kanidm.nix { inherit inputs; })
  (import ./pkgs.nix { inherit inputs; })
  (import ./unstable.nix { inherit inputs; })
  (import ./unfree.nix { inherit inputs; }) 
]


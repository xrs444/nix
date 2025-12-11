# overlays/all.nix
# Exports all overlays as a list for use in flake.nix
{ inputs }:
[
  (inputs.nix-vscode-extensions.overlays.default)
  (import ./kanidm.nix { inherit inputs; })
  (import ./nodejs.nix { inherit inputs; })
  (import ./unstable.nix { inherit inputs; })
  (import ./unfree.nix { inherit inputs; })
]

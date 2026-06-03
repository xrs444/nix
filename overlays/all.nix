# overlays/all.nix
# Exports all overlays as a list for use in flake.nix
{ inputs }:
[
  # Using specific commit bd97792786ef43285579d50ef353a4b867756e10 from PR #150
  # as workaround for upstream invalid store path bug
  inputs.nix-vscode-extensions.overlays.default
  (import ./pkgs.nix { inherit inputs; })
  (import ./kanidm.nix { inherit inputs; })
  (import ./nodejs.nix { inherit inputs; })
  (import ./unstable.nix { inherit inputs; })
  (import ./unfree.nix { inherit inputs; })
  (import ./gjs-fix.nix { inherit inputs; })
]

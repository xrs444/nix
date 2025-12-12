# overlays/all.nix
# Exports all overlays as a list for use in flake.nix
{ inputs }:
[
  # Temporarily disabled due to invalid store path in upstream nix-vscode-extensions
  # Error: path '/nix/store/zkab67l0irvrpdhbh0h52w035wb21bn5-nix-dev' is not valid
  # This is baked into revision 1778f178603ed65b4e4033c64f04ea51142ad6f6
  # Workaround: Use vscode-extensions from nixpkgs or wait for upstream fix
  # (inputs.nix-vscode-extensions.overlays.default)
  (import ./kanidm.nix { inherit inputs; })
  (import ./nodejs.nix { inherit inputs; })
  (import ./unstable.nix { inherit inputs; })
  (import ./unfree.nix { inherit inputs; })
]

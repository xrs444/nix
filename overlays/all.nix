# overlays/all.nix
# Exports all overlays as a list for use in flake.nix
{ inputs }:
[
  # Must come before nix-vscode-extensions so that when the vscode overlay
  # evaluates prev.vscode-extensions.ms-python.python it gets debugpy/django
  # with doCheck=false already in prev — otherwise it captures the original
  # derivations and our overlay has no effect on the extension dep chain.
  (import ./python-no-tests.nix)
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

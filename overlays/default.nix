# overlays/default.nix
# Loads all overlays in the correct order
{ inputs }:
let
  unfree = import ./unfree.nix;
  kanidm = import ./kanidm.nix { inherit inputs; };
  pkgs = import ./pkgs.nix { inherit inputs; };
  unstable = import ./unstable.nix { inherit inputs; };
  overlaysList = [
    unfree
    kanidm
    pkgs
    unstable
  ];
in builtins.trace "DEBUG: overlaysList type: ${builtins.typeOf overlaysList}" overlaysList

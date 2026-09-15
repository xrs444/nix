# overlays/all.nix
# Exports all overlays as a list for use in flake.nix
{ inputs }:
[
  # Using specific commit bd97792786ef43285579d50ef353a4b867756e10 from PR #150
  # as workaround for upstream invalid store path bug
  inputs.nix-vscode-extensions.overlays.default
  (import ./pkgs.nix { inherit inputs; })
  (import ./kanidm.nix { inherit inputs; })
  (import ./unstable.nix { inherit inputs; })
  (import ./unfree.nix { inherit inputs; })
  # gjs-fix.nix removed 2026-09-15 (bug-940): worked around gjs-1.86.0 meson
  # build failures with a from-source override; current pin builds gjs-1.88.0
  # and vanilla is cached (narinfo 200) — the override was the only reason
  # ours wasn't. If a NEW gjs meson failure appears, check `just
  # check-overlay-cache` first; if a from-source build really is needed, the
  # old file's full analysis is recoverable from git history
  # (nix/overlays/gjs-fix.nix, removed in this commit).
]

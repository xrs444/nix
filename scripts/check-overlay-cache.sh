#!/usr/bin/env bash
# Detect overlay overrides that changed a package's derivation hash for a
# reason that no longer holds — i.e. the vanilla (zero-overlay) package is
# cached on cache.nixos.org at the currently pinned nixpkgs revision, but our
# overlay-patched version is not, so every build pays for a from-source
# rebuild of that package and its whole reverse-dependency cone for no
# remaining benefit.
#
# Background: nix/overlays/pkgs.nix accumulated ~15 overrides (doCheck=false,
# ninjaFlags, withPlacebo=false, etc.), each justified at the time by a
# `curl -sI cache.nixos.org/<hash>.narinfo` 404. Nothing re-checks that
# assumption after a flake.lock bump — Hydra eventually builds the package,
# the 404 becomes a 200, and the override silently flips from "works around
# an uncached build" to "forces an otherwise-cached build from source". Found
# 2026-09-15 after ffmpeg-headless and libxkbcommon/tinysparql overrides
# turned into fleet-wide multi-hour CI runs (root-caused via `nix why-depends`
# + this exact narinfo-diff technique, done by hand). This script automates
# that check so the next flake.lock bump surfaces newly-redundant overrides
# instead of silently paying for them.
#
# Usage: scripts/check-overlay-cache.sh [system ...]
#   Defaults to x86_64-linux and aarch64-linux (Darwin substituter behavior
#   differs enough — and the Darwin-only overrides are few — that it's out of
#   scope for now; check those by hand if touched).
#
# Exit status: 0 if every checked attr is either SAME as vanilla, or DIFF but
# vanilla itself isn't cached (a genuine from-source build, override justified).
# Non-zero if any attr is DIFF with vanilla cached (a regression).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Attributes touched by an override in overlays/*.nix that changes the
# derivation hash (doCheck/doInstallCheck/ninjaFlags/override/postPatch/...).
# Keep in sync by hand with overlays/pkgs.nix and overlays/gjs-fix.nix — this
# is a known-list check, not a static analysis of the overlay files.
ATTRS=(
  gjs
  yt-dlp
  libxkbcommon
  libsecret
  sdl3
  gtkmm4
  gtksourceview5
  webkitgtk_4_1
  webkitgtk_6_0
  libnice
  gtk-layer-shell
  gnome-autoar
  tinysparql
  ffmpeg-headless
  pipx
  python313Packages.django
  python313Packages.rich
  python313Packages.curl-cffi
  python313Packages.pygobject3
)

# ${@:-...} with an unquoted default doesn't word-split as separate args when
# $@ is empty (it's a single string) — branch explicitly instead.
if [ "$#" -eq 0 ]; then
  SYSTEMS=(x86_64-linux aarch64-linux)
else
  SYSTEMS=("$@")
fi

# Any host whose pkgs are evaluated on that system — just needs to exist in
# flake.nix with a matching hostPlatform. These are used purely to reach
# `.pkgs.<attr>`; the actual package build doesn't depend on which host.
declare -A HOST_FOR_SYSTEM=(
  [x86_64-linux]="xsvr1"
  [aarch64-linux]="xlt1-t-vnixos"
)

NIXPKGS_REV=$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes[.locks.nodes[.locks.root].inputs.nixpkgs].locked.rev')
if [ -z "$NIXPKGS_REV" ] || [ "$NIXPKGS_REV" = "null" ]; then
  echo "ERROR: could not resolve locked nixpkgs revision from flake.lock" >&2
  exit 1
fi
echo "Checking against nixpkgs rev $NIXPKGS_REV"

NPKGS_SRC=$(nix eval --raw --no-warn-dirty ".#nixosConfigurations.${HOST_FOR_SYSTEM[x86_64-linux]}.pkgs.path" 2>/dev/null || true)
if [ -z "$NPKGS_SRC" ]; then
  echo "ERROR: could not resolve nixpkgs source path" >&2
  exit 1
fi

narinfo_code() {
  local storepath="$1"
  local hash
  hash=$(basename "$storepath" | cut -c1-32)
  curl -so /dev/null -w '%{http_code}' "https://cache.nixos.org/${hash}.narinfo"
}

regressions=0

for system in "${SYSTEMS[@]}"; do
  host="${HOST_FOR_SYSTEM[$system]:-}"
  if [ -z "$host" ]; then
    echo "WARNING: no reference host configured for system '$system', skipping" >&2
    continue
  fi
  echo
  echo "=== $system (via nixosConfigurations.$host.pkgs) ==="
  printf '%-32s %-6s %-6s %-6s\n' "attr" "cmp" "ours" "vanilla"
  for attr in "${ATTRS[@]}"; do
    ours_path=$(nix eval --raw --no-warn-dirty ".#nixosConfigurations.${host}.pkgs.${attr}.outPath" 2>/dev/null || true)
    if [ -z "$ours_path" ]; then
      printf '%-32s %-6s\n' "$attr" "EVAL_FAIL(ours)"
      continue
    fi
    vanilla_path=$(nix eval --raw --impure --expr \
      "(import ${NPKGS_SRC} { system = \"${system}\"; config.allowUnfree = true; }).${attr}.outPath" \
      2>/dev/null || true)
    if [ -z "$vanilla_path" ]; then
      printf '%-32s %-6s\n' "$attr" "EVAL_FAIL(vanilla)"
      continue
    fi

    ours_hash=$(basename "$ours_path" | cut -c1-32)
    vanilla_hash=$(basename "$vanilla_path" | cut -c1-32)
    cmp="SAME"
    [ "$ours_hash" != "$vanilla_hash" ] && cmp="DIFF"

    ours_code=$(narinfo_code "$ours_path")
    vanilla_code=$(narinfo_code "$vanilla_path")

    printf '%-32s %-6s %-6s %-6s' "$attr" "$cmp" "$ours_code" "$vanilla_code"
    if [ "$cmp" = "DIFF" ] && [ "$vanilla_code" = "200" ]; then
      printf '  <-- REGRESSION: override costs a cache hit that vanilla still has\n'
      regressions=$((regressions + 1))
    else
      printf '\n'
    fi
  done
done

echo
if [ "$regressions" -gt 0 ]; then
  echo "FAIL: $regressions overlay override(s) are forcing an otherwise-cached package out of the binary cache." >&2
  exit 1
fi
echo "OK: no overlay override is costing a cache hit vanilla nixpkgs still has."

#!/bin/sh
# Post-build hook: sign and push each derivation to the local file cache as
# soon as it is built. Invoked by the Nix daemon after each realised output;
# $OUT_PATHS is a space-separated list of store paths just built.
#
# Must use #!/bin/sh — /bin/bash does not exist on NixOS.
# The daemon's PATH already contains the nix store-path nix binary.
set -eu

# Split $OUT_PATHS into positional parameters. Nix store paths never contain
# spaces or glob characters, so this word-split is safe and intentional.
# shellcheck disable=SC2086
set -f; set -- $OUT_PATHS; set +f

nix store sign --key-file /run/secrets/nixcache_signing_key "$@"

# Purge stale narinfos: nix copy --to file:// skips paths whose narinfo already
# exists even if it lacks a trusted signature. Remove unsigned narinfos so that
# nix copy regenerates them with the signature we just applied.
for path in "$@"; do
  hash=$(basename "$path" | cut -d- -f1)
  narinfo="/zfs/nixcache/cache/${hash}.narinfo"
  if [ -f "$narinfo" ] && \
     ! grep -q "Sig: xsvr1.lan-1:" "$narinfo" && \
     ! grep -q "Sig: cache.nixos.org-1:" "$narinfo"; then
    rm -f "$narinfo"
  fi
done

nix copy --to "file:///zfs/nixcache/cache" "$@"

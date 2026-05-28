#!/bin/bash
# Post-build hook: sign and push each derivation to the local file cache as
# soon as it is built. Invoked by the Nix daemon after each realised output;
# $OUT_PATHS contains the space-separated store paths just built.
#
# Debug log written to /tmp/nix-hook-debug.log so CI can display it.
set -euf
exec >> /tmp/nix-hook-debug.log 2>&1

echo "--- hook invoked at $(date) ---"
echo "OUT_PATHS: ${OUT_PATHS:-UNSET}"
echo "PATH: $PATH"
command -v nix && echo "nix found at: $(command -v nix)" || echo "nix NOT in PATH"

# The daemon may not have the standard user PATH, so we add common Nix paths.
export PATH="/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"
command -v nix && echo "nix after PATH fix: $(command -v nix)" || echo "nix still NOT in PATH after fix"

nix store sign --key-file /run/secrets/nixcache_signing_key $OUT_PATHS

# Purge stale narinfos: nix copy --to file:// skips paths whose narinfo already
# exists even if it lacks a trusted signature. Remove unsigned narinfos so that
# nix copy regenerates them with the signature we just applied.
for path in $OUT_PATHS; do
  hash=$(basename "$path" | cut -d- -f1)
  narinfo="/zfs/nixcache/cache/${hash}.narinfo"
  if [[ -f "$narinfo" ]] && \
     ! grep -q "Sig: xsvr1.lan-1:" "$narinfo" && \
     ! grep -q "Sig: cache.nixos.org-1:" "$narinfo"; then
    rm -f "$narinfo"
  fi
done

nix copy --to "file:///zfs/nixcache/cache" $OUT_PATHS
echo "--- hook done ---"

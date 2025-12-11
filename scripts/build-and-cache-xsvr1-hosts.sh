#!/usr/bin/env bash
# Build and cache all hosts using xsvr1 as a remote builder
set -euo pipefail

# List all hosts to build
HOSTS=(xsvr1 xsvr2 xsvr3 xcomm1 xlabmgmt xdash1 xhac-radio xlt1-t-vnixos xts1 xts2)

# Path to your flake
FLAKE_PATH="/var/lib/comin/repository"

# Cache URL
CACHE_URL="http://nixcache.xrs444.net"

# Remote builder URL
REMOTE_BUILDER="ssh-ng://xsvr1"

for HOST in "${HOSTS[@]}"; do
  echo "Building $HOST on xsvr1..."
  nix build "$FLAKE_PATH#nixosConfigurations.$HOST.config.system.build.toplevel" --builders "$REMOTE_BUILDER"
  echo "Copying $HOST to cache..."
  nix copy --to "$CACHE_URL" "$FLAKE_PATH#nixosConfigurations.$HOST.config.system.build.toplevel"
done

echo "All hosts built on xsvr1 and cached."

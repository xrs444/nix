#!/usr/bin/env bash
# Build and cache all hosts using xsvr1 as a remote builder
set -euo pipefail

# List all hosts to build
HOSTS=(xsvr1 xsvr2 xsvr3 xcomm1 xlabmgmt xdash1 xhac-radio xlt1-t-vnixos xts1 xts2)

# Remote build host (use builder user for remote builds)
BUILD_HOST="builder@xsvr1.lan"
# Path to your flake on the remote host
REMOTE_FLAKE_PATH="/var/lib/comin/repository"
# Cache URL
CACHE_URL="http://nixcache.xrs444.net"

echo "Building all hosts on xsvr1 and caching them..."
echo ""

# Build all hosts on xsvr1 directly via SSH
for HOST in "${HOSTS[@]}"; do
  echo "====================================="
  echo "Building $HOST on xsvr1..."
  echo "====================================="

  ssh "$BUILD_HOST" "cd $REMOTE_FLAKE_PATH && nix build .#nixosConfigurations.$HOST.config.system.build.toplevel --print-build-logs"

  echo ""
  echo "Copying $HOST to cache..."
  ssh "$BUILD_HOST" "cd $REMOTE_FLAKE_PATH && nix copy --to $CACHE_URL .#nixosConfigurations.$HOST.config.system.build.toplevel"

  echo "✓ $HOST completed"
  echo ""
done

echo "====================================="
echo "All hosts built and cached successfully!"
echo "====================================="

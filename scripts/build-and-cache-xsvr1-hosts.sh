#!/usr/bin/env bash
# Build and cache all hosts using xsvr1 as a remote builder
set -euo pipefail

# List all hosts to build
HOSTS=(xsvr1 xsvr2 xsvr3 xcomm1 xlabmgmt xdash1 xhac-radio xlt1-t-vnixos xts1 xts2)

# Remote build host (use builder user via SSH config alias)
BUILD_HOST="xsvr1-builder"
# Path to builds on ZFS
REMOTE_FLAKE_PATH="/zfs/nixcache/builds"
# Cache directory on xsvr1 ZFS (local to the builder)
# CACHE_DIR="/zfs/nixcache/cache"

GIT_REPO="https://github.com/xrs444/nix"
GIT_BRANCH="testing"  # Build from testing branch before deploying to main

echo "Building all hosts on xsvr1 from ${GIT_BRANCH} branch and caching them..."
echo ""

# Pull latest config from git
echo "====================================="
echo "Pulling latest config from ${GIT_BRANCH} branch..."
echo "====================================="
ssh "$BUILD_HOST" "
  if [ -d $REMOTE_FLAKE_PATH ]; then
    cd $REMOTE_FLAKE_PATH &&
    nix run nixpkgs#git -- fetch origin &&
    nix run nixpkgs#git -- checkout $GIT_BRANCH &&
    nix run nixpkgs#git -- pull origin $GIT_BRANCH
  else
    GIT_TERMINAL_PROMPT=0 nix run nixpkgs#git -- clone -b $GIT_BRANCH $GIT_REPO $REMOTE_FLAKE_PATH
  fi
"

# Build all hosts on xsvr1 directly via SSH
for HOST in "${HOSTS[@]}"; do
  echo ""
  echo "====================================="
  echo "Building $HOST on xsvr1..."
  echo "====================================="

  ssh "$BUILD_HOST" "cd $REMOTE_FLAKE_PATH && nix build .#nixosConfigurations.$HOST.config.system.build.toplevel --accept-flake-config --print-build-logs"

  echo ""
  echo "Copying $HOST to cache..."
  # Copy to ZFS cache directory on xsvr1
  ssh "$BUILD_HOST" "cd $REMOTE_FLAKE_PATH && nix copy --to 'file:///zfs/nixcache/cache?compression=zstd' --accept-flake-config .#nixosConfigurations.$HOST.config.system.build.toplevel"

  echo "✓ $HOST completed"
  echo ""
done

echo "====================================="
echo "All hosts built and cached successfully!"
echo "====================================="

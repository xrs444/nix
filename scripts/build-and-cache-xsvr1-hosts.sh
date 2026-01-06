#!/usr/bin/env bash
# Build and cache all hosts using xsvr1 as a remote builder
set -euo pipefail

# List all hosts to build
HOSTS=(xsvr1 xsvr2 xsvr3 xcomm1 xlabmgmt xdash1 xhac-radio xlt1-t-vnixos xts1 xts2)

# Remote build host (use builder user via SSH config alias)
BUILD_HOST="xsvr1-builder"
# Path to your flake on the remote host
REMOTE_FLAKE_PATH="/home/builder/nix"
# Cache URL
CACHE_URL="http://nixcache.xrs444.net"
# Git repository URL
GIT_REPO="https://github.com/xrs444/HomeProd.git"

echo "Building all hosts on xsvr1 and caching them..."
echo ""

# Pull latest config from git
echo "====================================="
echo "Pulling latest config from git..."
echo "====================================="
ssh "$BUILD_HOST" "
  if [ -d $REMOTE_FLAKE_PATH ]; then
    cd $REMOTE_FLAKE_PATH && nix run nixpkgs#git -- pull
  else
    nix run nixpkgs#git -- clone $GIT_REPO $REMOTE_FLAKE_PATH
  fi
"

# Build all hosts on xsvr1 directly via SSH
for HOST in "${HOSTS[@]}"; do
  echo ""
  echo "====================================="
  echo "Building $HOST on xsvr1..."
  echo "====================================="

  ssh "$BUILD_HOST" "cd $REMOTE_FLAKE_PATH/nix && nix build .#nixosConfigurations.$HOST.config.system.build.toplevel --print-build-logs"

  echo ""
  echo "Copying $HOST to cache..."
  ssh "$BUILD_HOST" "cd $REMOTE_FLAKE_PATH/nix && nix copy --to $CACHE_URL .#nixosConfigurations.$HOST.config.system.build.toplevel"

  echo "✓ $HOST completed"
  echo ""
done

echo "====================================="
echo "All hosts built and cached successfully!"
echo "====================================="

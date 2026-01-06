#!/usr/bin/env bash

# Simple deployment using nixos-anywhere with QEMU emulation
# This builds on your Mac using QEMU to emulate aarch64-linux

set -euo pipefail

HOST="xdash1"
TARGET_IP="${1:-}"
TARGET_USER="${2:-root}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ -z "$TARGET_IP" ]; then
    echo "Usage: $0 <target-ip> [target-user]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$FLAKE_DIR"

echo_info "Deploying xdash1 to ${TARGET_IP}"
echo_warn "This will WIPE /dev/mmcblk0!"
echo_warn "Building with QEMU emulation (may be slow)"
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Enable QEMU for aarch64 builds on macOS
echo_info "Note: This uses QEMU to build ARM binaries on your Mac"
echo_info "It will be slow but doesn't require kexec"

nix run github:nix-community/nixos-anywhere -- \
    --flake ".#${HOST}" \
    --extra-experimental-features "nix-command flakes" \
    "${TARGET_USER}@${TARGET_IP}"

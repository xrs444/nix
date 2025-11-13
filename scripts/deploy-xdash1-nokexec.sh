#!/usr/bin/env bash

# Deploy NixOS to xdash1 using SSH install method (no kexec)
# This uses the disko module directly on the running system

set -euo pipefail

HOST="xdash1"
TARGET_IP="${1:-}"
TARGET_USER="${2:-root}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ -z "$TARGET_IP" ]; then
    echo_error "Usage: $0 <target-ip> [target-user]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$FLAKE_DIR"

echo_info "Deploying NixOS to ${HOST} at ${TARGET_IP} (SSH mode)"
echo_warn "This will WIPE the target disk!"
echo_warn "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Use nixos-anywhere with the --phases option to skip kexec
echo_info "Starting deployment (skipping kexec phase)..."
echo_info "Building locally on your Mac and copying to target..."
nixos-anywhere \
    --flake ".#${HOST}" \
    --no-reboot \
    --phases "disko,install" \
    "${TARGET_USER}@${TARGET_IP}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo_info "Installation complete!"
    echo_warn "Reboot the system:"
    echo_info "  ssh ${TARGET_USER}@${TARGET_IP} 'reboot'"
else
    echo_error "Deployment failed with exit code $EXIT_CODE"
    exit 1
fi

#!/usr/bin/env bash

# Deploy NixOS to xdash1 using nixos-anywhere
# This will install NixOS over the existing DietPi installation

set -euo pipefail

# Configuration
HOST="xdash1"
TARGET_IP="${1:-}" # Pass IP address as first argument
TARGET_USER="${2:-root}" # Default to root, or pass as second argument
FLAKE_ATTR="#nixosConfigurations.${HOST}.config.system.build.toplevel"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate arguments
if [ -z "$TARGET_IP" ]; then
    echo_error "Usage: $0 <target-ip> [target-user]"
    echo_error "Example: $0 192.168.1.100 root"
    exit 1
fi

# Check if nixos-anywhere is installed
if ! command -v nixos-anywhere &> /dev/null; then
    echo_info "nixos-anywhere not found. Installing..."
    nix profile install github:nix-community/nixos-anywhere
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$FLAKE_DIR"

echo_info "Deploying NixOS to ${HOST} at ${TARGET_IP}"
echo_warn "This will WIPE the target disk and install NixOS!"
echo_warn "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Run nixos-anywhere
echo_info "Starting nixos-anywhere deployment..."
nixos-anywhere \
    --flake ".#${HOST}" \
    --build-on-remote \
    "${TARGET_USER}@${TARGET_IP}"

echo_info "Deployment complete!"
echo_info "The system should reboot into NixOS automatically."
echo_info "You can SSH into it using: ssh thomas-local@${TARGET_IP}"

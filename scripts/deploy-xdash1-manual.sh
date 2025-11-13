#!/usr/bin/env bash

# Manual NixOS installation for xdash1 (without kexec)
# Use this when nixos-anywhere's kexec method fails on ARM devices

set -euo pipefail

# Configuration
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

echo_info "Manual NixOS installation for ${HOST} at ${TARGET_IP}"
echo_warn "This will install NixOS directly on the running DietPi system"
echo_warn "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Step 1: Install Nix on the target system
echo_info "Step 1: Installing Nix on target system..."
ssh "${TARGET_USER}@${TARGET_IP}" 'bash <(curl -L https://nixos.org/nix/install) --daemon --yes' || {
    echo_warn "Nix might already be installed, continuing..."
}

# Step 2: Enable experimental features
echo_info "Step 2: Configuring Nix..."
ssh "${TARGET_USER}@${TARGET_IP}" 'mkdir -p /etc/nix && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf'

# Step 3: Partition and format the disk using disko
echo_info "Step 3: Partitioning disk with disko..."
echo_warn "THIS WILL WIPE /dev/mmcblk0!"
sleep 3

# Build the disko script - let nix decide where to build it
echo_info "Building disko configuration (this may use remote builders or emulation)..."
DISKO_SCRIPT=$(nix build --print-out-paths ".#nixosConfigurations.${HOST}.config.system.build.diskoScript" 2>&1)

if [ $? -ne 0 ]; then
    echo_warn "Local build failed, trying to build on target..."
    # Copy flake to target and build there
    echo_info "Copying flake to target..."
    ssh "${TARGET_USER}@${TARGET_IP}" "mkdir -p /tmp/nixos-config"
    scp -r "${FLAKE_DIR}"/* "${TARGET_USER}@${TARGET_IP}:/tmp/nixos-config/"
    
    echo_info "Building disko on target..."
    ssh "${TARGET_USER}@${TARGET_IP}" "cd /tmp/nixos-config && nix build .#nixosConfigurations.${HOST}.config.system.build.diskoScript --out-link /tmp/disko-script"
    
    DISKO_SCRIPT="/tmp/disko-script"
else
    # Copy disko script to target
    echo_info "Copying disko script to target..."
    scp "${DISKO_SCRIPT}" "${TARGET_USER}@${TARGET_IP}:/tmp/disko-script"
    DISKO_SCRIPT="/tmp/disko-script"
fi

# Run disko on target
echo_info "Running disko (this will partition and format the disk)..."
ssh "${TARGET_USER}@${TARGET_IP}" 'chmod +x /tmp/disko-script && /tmp/disko-script'

# Step 4: Build and install NixOS
echo_info "Step 4: Building NixOS configuration..."

# Try building locally first, fall back to building on target
SYSTEM=$(nix build --print-out-paths ".#nixosConfigurations.${HOST}.config.system.build.toplevel" 2>&1)

if [ $? -ne 0 ]; then
    echo_warn "Local build failed, building on target instead..."
    ssh "${TARGET_USER}@${TARGET_IP}" "cd /tmp/nixos-config && nix build .#nixosConfigurations.${HOST}.config.system.build.toplevel --out-link /tmp/system"
    SYSTEM="/tmp/system"
    BUILT_ON_TARGET=true
else
    BUILT_ON_TARGET=false
    echo_info "Copying system closure to target (this may take a while)..."
    nix copy --to "ssh://${TARGET_USER}@${TARGET_IP}" "${SYSTEM}"
fi

# Install NixOS
echo_info "Running nixos-install..."
ssh "${TARGET_USER}@${TARGET_IP}" "nixos-install --system ${SYSTEM} --root /mnt --no-root-password"

echo_info "Installation complete!"
echo_warn "Reboot the system manually:"
echo_info "  ssh ${TARGET_USER}@${TARGET_IP} 'reboot'"
echo_info "After reboot, SSH using: ssh thomas-local@${TARGET_IP}"

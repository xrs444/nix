#!/usr/bin/env bash

# Deploy using a custom kexec tarball for ARM
# This downloads the NixOS kexec tarball and boots into it manually

set -euo pipefail

HOST="xdash1"
TARGET_IP="${1:-}"
TARGET_USER="${2:-root}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo_info "Two-stage deployment to ${HOST}"
echo_warn "Stage 1: Boot into NixOS installer via kexec"
echo_warn "Stage 2: Install NixOS to disk"

# Download and extract kexec tarball on target
echo_info "Downloading NixOS kexec tarball to target..."
ssh "${TARGET_USER}@${TARGET_IP}" << 'EOF'
set -e
cd /root
curl -L https://github.com/nix-community/nixos-images/releases/latest/download/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz | tar -xzf-
echo "Kexec tarball extracted"
ls -la /root/kexec*
EOF

echo_warn "Now we need to boot into the kexec environment"
echo_info "Run this command on the target:"
echo_info "  /root/kexec_nixos"
echo_info ""
echo_warn "After it reboots into NixOS installer, run:"
echo_info "  ./scripts/deploy-xdash1-stage2.sh ${TARGET_IP}"

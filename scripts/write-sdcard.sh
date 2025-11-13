#!/usr/bin/env bash

# Write the NixOS SD card image to an SD card
# Usage: ./write-sdcard.sh [device]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$FLAKE_DIR"

# Find the SD image
IMAGE=$(find ./result/sd-image -name "*.img" 2>/dev/null | head -1)

if [ -z "$IMAGE" ]; then
    echo_error "No SD image found in ./result/sd-image/"
    echo_info "Build the image first with: nix build .#nixosConfigurations.xdash1.config.system.build.sdImage"
    exit 1
fi

echo_info "Found image: $IMAGE"
IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
echo_info "Image size: $IMAGE_SIZE"

# List available disks
echo_info "Available disks:"
diskutil list

echo ""
DEVICE="${1:-}"

if [ -z "$DEVICE" ]; then
    echo_warn "Usage: $0 /dev/diskX"
    echo_warn "Example: $0 /dev/disk4"
    echo ""
    echo_info "Find your SD card in the list above and run:"
    echo_info "  $0 /dev/diskN"
    exit 1
fi

# Validate device
if [[ ! "$DEVICE" =~ ^/dev/disk[0-9]+$ ]]; then
    echo_error "Invalid device: $DEVICE"
    echo_error "Device must be in format: /dev/diskN (e.g., /dev/disk4)"
    exit 1
fi

# Show disk info
echo_info "Target disk info:"
diskutil info "$DEVICE" || {
    echo_error "Could not get info for $DEVICE"
    exit 1
}

echo ""
echo_warn "⚠️  THIS WILL ERASE ALL DATA ON $DEVICE ⚠️"
echo_warn "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Unmount the disk
echo_info "Unmounting $DEVICE..."
diskutil unmountDisk "$DEVICE"

# Write the image (using rdisk for faster raw writes)
RAW_DEVICE="${DEVICE/disk/rdisk}"
echo_info "Writing image to $RAW_DEVICE (this will take several minutes)..."
sudo dd if="$IMAGE" of="$RAW_DEVICE" bs=4m status=progress

echo_info "Ejecting disk..."
diskutil eject "$DEVICE"

echo_info "✅ SD card is ready!"
echo_info "You can now remove the SD card and insert it into your OrangePi"
echo_info "The system will auto-expand the root partition on first boot"

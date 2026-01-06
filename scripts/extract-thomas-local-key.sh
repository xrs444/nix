#!/usr/bin/env bash
# Extract thomas-local SSH private key from sops and save it locally
# This script is for use on macOS/Darwin systems where xrs444 needs the thomas-local key

set -e

KEY_PATH="$HOME/.ssh/thomas-local_key"
SECRETS_FILE="$(dirname "$0")/../secrets/thomas-local-ssh-key.yaml"

if [ ! -f "$SECRETS_FILE" ]; then
  echo "Error: Secrets file not found at $SECRETS_FILE"
  exit 1
fi

echo "Extracting thomas-local private key from sops..."
mkdir -p "$HOME/.ssh"

# Extract just the key content, removing YAML indentation
sops -d "$SECRETS_FILE" 2>/dev/null | awk '/-----BEGIN/,/-----END/' | sed 's/^    //' > "$KEY_PATH"
chmod 600 "$KEY_PATH"

echo "Private key saved to $KEY_PATH"
echo "You can now use: ssh thomas-local@hostname"
echo ""
echo "Note: Make sure the corresponding public key is deployed to target hosts"
echo "by rebuilding the NixOS configuration which includes modules/users/thomas-local.nix"

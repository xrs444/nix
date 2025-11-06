#!/usr/bin/env bash
# filepath: scripts/new-host.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if hostname is provided
if [ $# -ne 2 ]; then
    print_error "Usage: $0 <hostname> <platform>"
    print_error "Platform must be: nixos or darwin"
    exit 1
fi

HOSTNAME="$1"
PLATFORM="$2"

# Validate platform
if [[ "$PLATFORM" != "nixos" && "$PLATFORM" != "darwin" ]]; then
    print_error "Platform must be either 'nixos' or 'darwin'"
    exit 1
fi

# Get the root of the repository
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_DIR="$REPO_ROOT/hosts/$PLATFORM/$HOSTNAME"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
SECRETS_DIR="$REPO_ROOT/secrets"

print_info "Creating new host: $HOSTNAME (platform: $PLATFORM)"

# Check if host already exists
if [ -d "$HOST_DIR" ]; then
    print_error "Host directory already exists: $HOST_DIR"
    exit 1
fi

# Create host directory structure
print_info "Creating host directory: $HOST_DIR"
mkdir -p "$HOST_DIR"

# Generate age key for the host
print_info "Generating SOPS age key for host..."
KEYS_DIR="$HOST_DIR/.age"
mkdir -p "$KEYS_DIR"
AGE_KEY_FILE="$KEYS_DIR/keys.txt"

# Generate the key
age-keygen -o "$AGE_KEY_FILE" 2>/dev/null

# Extract the public key
PUBLIC_KEY=$(age-keygen -y "$AGE_KEY_FILE")
print_info "Generated public key: $PUBLIC_KEY"

# Create default.nix template
print_info "Creating default.nix..."
cat > "$HOST_DIR/default.nix" << EOF
{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
  ];

  # System configuration
  system.stateVersion = "24.11";
  
  # Hostname
  networking.hostName = "$HOSTNAME";
  
  # Add host-specific configuration here
}
EOF

# Create network.nix template
print_info "Creating network.nix..."
cat > "$HOST_DIR/network.nix" << EOF
{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:
{
  networking = {
    # Network configuration for $HOSTNAME
    useDHCP = lib.mkDefault true;
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };
}
EOF

# Create disks.nix template for NixOS hosts
if [ "$PLATFORM" = "nixos" ]; then
    print_info "Creating disks.nix..."
    cat > "$HOST_DIR/disks.nix" << EOF
{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:
{
  # Disk configuration for $HOSTNAME
  # Add disko or traditional partition configuration here
  
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  
  swapDevices = [ ];
}
EOF
fi

# Create hardware-configuration.nix placeholder
print_info "Creating hardware-configuration.nix placeholder..."
cat > "$HOST_DIR/hardware-configuration.nix" << EOF
{
  config,
  hostname,
  lib,
  modulesPath,
  pkgs,
  platform,
  ...
}:
{
  imports = [ ];

  # Generate with: nixos-generate-config --show-hardware-config
  # Or for disko setups, use disko-install
  
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
EOF

# Update .sops.yaml with new host key
print_info "Updating .sops.yaml with new host key..."

# Create a temporary file for the updated .sops.yaml
TEMP_SOPS=$(mktemp)

# Read the current .sops.yaml and add the new host key
awk -v hostname="$HOSTNAME" -v pubkey="$PUBLIC_KEY" '
/^keys:/ {
    print
    in_keys = 1
    next
}
in_keys && /^  - &/ {
    # Store all existing keys
    keys[++key_count] = $0
    next
}
in_keys && /^$/ {
    # End of keys section, print all keys plus new one
    for (i = 1; i <= key_count; i++) {
        print keys[i]
    }
    print "  - &host_" hostname " " pubkey
    in_keys = 0
    print
    next
}
in_keys {
    keys[key_count] = keys[key_count] "\n" $0
    next
}
/^creation_rules:/ {
    in_rules = 1
    print
    next
}
in_rules && /^  - path_regex:/ {
    in_path_regex = 1
    print
    next
}
in_path_regex && /^    - age:/ {
    print
    next
}
in_path_regex && /^      - \*/ {
    # Collect age keys
    age_keys[++age_count] = $0
    next
}
in_path_regex && /^      - \*host_/ {
    age_keys[++age_count] = $0
    next
}
in_path_regex && (/^  - path_regex:/ || /^$/ || !/^      /) {
    # End of this rule, print collected keys plus new one
    for (i = 1; i <= age_count; i++) {
        print age_keys[i]
    }
    print "      - *host_" hostname
    delete age_keys
    age_count = 0
    in_path_regex = 0
    print
    next
}
{ print }
' "$SOPS_YAML" > "$TEMP_SOPS"

# Backup original .sops.yaml
cp "$SOPS_YAML" "$SOPS_YAML.backup"
mv "$TEMP_SOPS" "$SOPS_YAML"

print_info "Backed up .sops.yaml to .sops.yaml.backup"
print_info "Updated .sops.yaml with host key reference"

# Rekey all secrets
print_info "Rekeying all secrets..."
for secret_file in "$SECRETS_DIR"/*.yaml; do
    if [ -f "$secret_file" ]; then
        filename=$(basename "$secret_file")
        print_info "  Rekeying $filename..."
        sops updatekeys "$secret_file" || print_warn "  Failed to rekey $filename"
    fi
done

# Update flake.nix
print_info "Please manually update flake.nix to include the new host:"
print_warn "Add to outputs.nixosConfigurations (for nixos) or outputs.darwinConfigurations (for darwin):"
echo ""
echo "    $HOSTNAME = inputs.nixpkgs.lib.nixosSystem {"
echo "      system = \"x86_64-linux\";"
echo "      specialArgs = inputs // {"
echo "        hostname = \"$HOSTNAME\";"
echo "        platform = \"$PLATFORM\";"
echo "      };"
echo "      modules = ["
echo "        ./hosts/$PLATFORM/$HOSTNAME"
echo "        # Add other modules as needed"
echo "      ];"
echo "    };"
echo ""

print_info "✓ Host setup complete!"
print_info ""
print_info "Next steps:"
print_info "1. Update flake.nix with the new host configuration (see above)"
print_info "2. Edit $HOST_DIR/default.nix with host-specific configuration"
print_info "3. Edit $HOST_DIR/network.nix with network settings"
if [ "$PLATFORM" = "nixos" ]; then
    print_info "4. Edit $HOST_DIR/disks.nix with disk configuration"
    print_info "5. Generate hardware-configuration.nix: nixos-generate-config --root /mnt --show-hardware-config > $HOST_DIR/hardware-configuration.nix"
fi
print_info ""
print_info "Age key location: $AGE_KEY_FILE"
print_info "Public key: $PUBLIC_KEY"
print_info ""
print_warn "IMPORTANT: The age private key should be deployed to the host at:"
print_warn "  /var/lib/private/sops/age/keys.txt (for nixos)"
print_warn "  ~/.config/sops/age/keys.txt (for darwin)"
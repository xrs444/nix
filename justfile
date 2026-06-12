# HomeProd Nix Management Tasks
# Run 'just --list' to see all available recipes

# Set shell to fish
set shell := ["fish", "-c"]

# Default recipe - show help
default:
    @just --list

# Variables
scripts_dir := justfile_directory()
flake_dir := scripts_dir / ".."

# Build Operations
# ================

# Build SD card image for a host (default: xts1)
build-sdimage host="xts1":
    nix build .#nixosConfigurations.{{host}}.config.system.build.sdImage
    @echo "SD image built successfully in ./result/sd-image/"

# Build a specific host configuration
build host:
    nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel
    @echo "Build complete for {{host}}"

# Build and cache all hosts (run on xsvr1 where the nix store is local)
build-and-cache-all:
    #!/usr/bin/env fish
    set -l hosts xsvr1 xsvr2 xsvr3 xcomm1 xlt1-t-vnixos xts1 xts2 cmrpi1 xpbx1
    set -l cache_url "file:///zfs/nixcache/cache"

    echo "Building all hosts in parallel..."
    for host in $hosts
        nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link &
    end
    wait

    echo "Caching all hosts..."
    for host in $hosts
        echo "Caching $host..."
        nix copy --to $cache_url ".#nixosConfigurations.$host.config.system.build.toplevel" || true
    end

    echo "All hosts built and cached"

# Deploy a single remote host via deploy-rs (not xsvr1)
deploy host:
    deploy ".#{{host}}"

# Deploy all remote hosts via deploy-rs, then trigger xsvr1 self-deploy via path unit
# (nixos-rebuild must run as a systemd service to have systemctl in PATH — same as CI)
deploy-all:
    deploy .
    touch /zfs/nixcache/builds/github-runner/nixos-rebuild-ci-permitted

# Trigger xsvr1 self-deploy (must run on xsvr1; uses path unit so systemd provides full env)
deploy-xsvr1:
    touch /zfs/nixcache/builds/github-runner/nixos-rebuild-ci-permitted

# SD Card Operations
# ==================

# Write SD card image to device (requires device path like /dev/disk4)
write-sdcard device:
    #!/usr/bin/env fish
    # Find the SD image
    set -l image (find ./result/sd-image -name "*.img" 2>/dev/null | head -1)
    
    if test -z "$image"
        echo "ERROR: No SD image found in ./result/sd-image/"
        echo "Build the image first with: just build-sdimage"
        exit 1
    end
    
    echo "Found image: $image"
    set -l image_size (du -h $image | cut -f1)
    echo "Image size: $image_size"
    
    # Validate device
    if not string match -qr '^/dev/disk[0-9]+$' {{device}}
        echo "ERROR: Invalid device: {{device}}"
        echo "Device must be in format: /dev/diskN (e.g., /dev/disk4)"
        exit 1
    end
    
    # Show disk info
    echo "Target disk info:"
    diskutil info {{device}} || begin
        echo "ERROR: Could not get info for {{device}}"
        exit 1
    end
    
    echo ""
    echo "⚠️  THIS WILL ERASE ALL DATA ON {{device}} ⚠️"
    echo "Press Ctrl+C to cancel, or Enter to continue..."
    read -P ""
    
    # Unmount the disk
    echo "Unmounting {{device}}..."
    diskutil unmountDisk {{device}}
    
    # Write the image (using rdisk for faster raw writes)
    set -l raw_device (string replace "disk" "rdisk" {{device}})
    echo "Writing image to $raw_device (this will take several minutes)..."
    sudo dd if=$image of=$raw_device bs=4m status=progress
    
    echo "Ejecting disk..."
    diskutil eject {{device}}
    
    echo "✅ SD card is ready!"
    echo "You can now remove the SD card and insert it into your device"

# List available disks for SD card writing
list-disks:
    @diskutil list

# Deployment Operations
# ======================

# Host Management
# ===============

# Create a new host configuration (platform: nixos or darwin)
new-host hostname platform:
    #!/usr/bin/env fish
    set -l hostname "{{hostname}}"
    set -l platform "{{platform}}"
    
    # Validate platform
    if test "$platform" != "nixos" -a "$platform" != "darwin"
        echo "ERROR: Platform must be either 'nixos' or 'darwin'"
        exit 1
    end
    
    set -l host_dir "{{flake_dir}}/hosts/$platform/$hostname"
    
    echo "Creating new host: $hostname (platform: $platform)"
    
    # Check if host already exists
    if test -d "$host_dir"
        echo "ERROR: Host directory already exists: $host_dir"
        exit 1
    end
    
    echo "⚠️  This is a simplified version. For full functionality, run:"
    echo "   {{scripts_dir}}/new-host.sh {{hostname}} {{platform}}"
    
    # Create basic structure
    mkdir -p $host_dir
    echo "Created host directory: $host_dir"
    echo "Please add configuration files and update flake.nix"

# Validation & Testing
# ====================

# Validate flake configuration
validate:
    @echo "Validating flake configuration..."
    nix flake check

# Update flake inputs
update:
    @echo "Updating flake inputs..."
    nix flake update

# Show flake info
info:
    @echo "Flake information:"
    @nix flake metadata
    @echo ""
    @echo "Available configurations:"
    @nix flake show

# Show outdated flake inputs
outdated:
    @echo "Checking for outdated inputs..."
    nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | select(.value.locked) | "\(.key): \(.value.locked.rev // .value.locked.narHash)"'

# Development
# ===========

# Enter a development shell (from shells/ directory)
dev shell="default":
    @echo "Entering {{shell}} development shell..."
    nix develop {{flake_dir}}/shells#{{shell}}

# Format nix files
fmt:
    @echo "Formatting Nix files..."
    nix fmt

# Cleanup
# =======

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    rm -rf result result-*
    @echo "Cleaned"

# Run garbage collection
gc:
    @echo "Running garbage collection..."
    nix-collect-garbage -d

# Optimize nix store
optimize:
    @echo "Optimizing Nix store..."
    nix-store --optimize

# Full cleanup: remove artifacts, gc, and optimize
deep-clean: clean gc optimize
    @echo "Deep clean complete"

# SSH & Secrets Management
# =========================

# Extract thomas-local SSH private key from sops
extract-thomas-local-key:
    #!/usr/bin/env fish
    set -l key_path "$HOME/.ssh/thomas-local_key"
    set -l secrets_file "{{scripts_dir}}/secrets/deploy-ssh-key.yaml"

    if not test -f "$secrets_file"
        echo "ERROR: Secrets file not found at $secrets_file"
        exit 1
    end

    echo "Extracting thomas-local private key from sops..."
    mkdir -p "$HOME/.ssh"

    # Extract just the key content, removing YAML indentation
    sops -d "$secrets_file" 2>/dev/null | awk '/-----BEGIN/,/-----END/' | sed 's/^    //' > "$key_path"
    chmod 600 "$key_path"

    echo "✅ Private key saved to $key_path"
    echo ""
    echo "You can now use: ssh thomas-local@hostname"
    echo ""
    echo "Note: The corresponding public key is deployed via NixOS configuration"

# Deploy thomas-local SSH key (from SOPS) to a Bazzite host for Ansible access
deploy-ssh-key hostname user="$USER":
    #!/usr/bin/env bash
    set -euo pipefail

    HOSTNAME="{{hostname}}"
    INITIAL_USER="{{user}}"
    SECRETS_FILE="{{scripts_dir}}/secrets/deploy-ssh-key.yaml"

    # Extract public key from SOPS-encrypted private key
    echo "Extracting public key from SOPS..."
    if [[ ! -f "$SECRETS_FILE" ]]; then
        echo "ERROR: Secrets file not found: $SECRETS_FILE"
        exit 1
    fi

    # Decrypt private key and extract public key using ssh-keygen
    TMP_KEY=$(mktemp)
    trap "rm -f $TMP_KEY" EXIT

    sops -d "$SECRETS_FILE" 2>/dev/null | awk '/-----BEGIN/,/-----END/' | sed 's/^    //' > "$TMP_KEY"
    chmod 600 "$TMP_KEY"

    SSH_PUBLIC_KEY=$(ssh-keygen -y -f "$TMP_KEY")

    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        echo "ERROR: Failed to extract public key from private key"
        exit 1
    fi

    echo "Deploying SSH key to $HOSTNAME"
    echo "Initial SSH user: $INITIAL_USER"
    echo "SSH public key: $SSH_PUBLIC_KEY"
    echo ""

    # Test SSH connectivity
    echo "Testing SSH connectivity to $HOSTNAME..."
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$INITIAL_USER@$HOSTNAME" "echo 'SSH connection successful'" 2>/dev/null; then
        echo "⚠️  Cannot connect with key-based auth, you may need to enter password"
    fi

    # Create the ansible user setup script
    echo "Creating ansible user on $HOSTNAME..."
    echo "Note: You may be prompted for sudo password"

    ssh -t "$INITIAL_USER@$HOSTNAME" 'bash -c "
        set -euo pipefail
        if [[ \$EUID -ne 0 ]]; then
            SUDO=\"sudo\"
        else
            SUDO=\"\"
        fi
        echo \"Creating ansible user...\"
        \$SUDO useradd -m -s /bin/bash -c \"Ansible automation user\" ansible 2>/dev/null || echo \"User ansible already exists\"
        \$SUDO usermod -aG wheel ansible
        echo \"ansible ALL=(ALL) NOPASSWD: ALL\" | \$SUDO tee /etc/sudoers.d/ansible > /dev/null
        \$SUDO chmod 0440 /etc/sudoers.d/ansible
        \$SUDO mkdir -p /home/ansible/.ssh
        \$SUDO chmod 700 /home/ansible/.ssh
        \$SUDO chown ansible:ansible /home/ansible/.ssh
        echo \"Ansible user setup complete\"
    "'

    # Deploy SSH key
    echo "Deploying SSH public key..."
    ssh -t "$INITIAL_USER@$HOSTNAME" "sudo bash -c 'echo \"$SSH_PUBLIC_KEY\" >> /home/ansible/.ssh/authorized_keys && chmod 600 /home/ansible/.ssh/authorized_keys && chown ansible:ansible /home/ansible/.ssh/authorized_keys && sort -u /home/ansible/.ssh/authorized_keys -o /home/ansible/.ssh/authorized_keys && echo \"SSH key deployed successfully\"'"

    # Test ansible user connection
    echo "Testing ansible user SSH connection..."
    if ssh -o ConnectTimeout=5 "ansible@$HOSTNAME" "echo 'Ansible user connection successful'" 2>/dev/null; then
        echo ""
        echo "✅ SSH key deployment successful!"
        echo ""
        echo "You can now connect with: ssh ansible@$HOSTNAME"
        echo "You can now run Ansible playbooks against $HOSTNAME"
    else
        echo ""
        echo "ERROR: Failed to connect as ansible user"
        echo "Please check the setup manually"
        exit 1
    fi

# Nixable/Bazzite Host Management
# ================================

# Run nixible playbook for a Bazzite host (xdt1-t, xdt2-g, or xdt3-r)
run-nixable host:
    @echo "Running nixible playbook for {{host}}..."
    @echo "This will be available after nixible is added to flake inputs"
    @echo "For now, use: nix run .#{{host}}"

# Install Ansible collections required for network gear management
# Run this once on any machine before using configure-xswcore or bootstrap-xswcore
install-collections:
    ansible-galaxy collection install -r "{{scripts_dir}}/hosts/nixable/xswcore/requirements.yml"

# Bootstrap xswcore: connect as ansible-local with password to create ansible-brocade + push RSA key.
# Run this ONCE before configure-xswcore. Uses vault_user_ansible_password from ansible-network.yaml.
bootstrap-xswcore:
    #!/usr/bin/env fish
    set -l secrets "{{scripts_dir}}/secrets/ansible-network.yaml"
    set -l inventory "{{scripts_dir}}/hosts/nixable/xswcore/inventory.yml"
    set -l tmp_vars (mktemp /tmp/net-vars-XXXXXX.yml)
    set -l tmp_conn (mktemp /tmp/net-conn-XXXXXX.yml)
    chmod 600 $tmp_vars $tmp_conn

    if not test -f $secrets
        echo "ERROR: Secrets file not found: $secrets"
        exit 1
    end

    if not sops -d $secrets > $tmp_vars
        rm -f $tmp_vars $tmp_conn
        echo "ERROR: Failed to decrypt $secrets"
        exit 1
    end

    # Extract bootstrap credentials (ansible-local password == ansible-brocade password)
    set -l boot_pass (sops -d --extract '["vault_user_ansible_password"]' $secrets | string trim)
    set -l enable_pass (sops -d --extract '["ansible_become_password"]' $secrets | string trim)

    # Write connection overrides to a separate vars file to avoid just variable interpolation
    printf "ansible_user: ansible-local\nansible_password: '%s'\nansible_become_password: '%s'\n" \
        (string replace --all "'" "''" $boot_pass) \
        (string replace --all "'" "''" $enable_pass) > $tmp_conn

    echo "Bootstrapping xswcore (password auth as ansible-local)..."
    set -x ANSIBLE_TERMINAL_PLUGINS "{{scripts_dir}}/hosts/nixable/xswcore/plugins/terminal"
    set -x ANSIBLE_CLICONF_PLUGINS "{{scripts_dir}}/hosts/nixable/xswcore/plugins/cliconf"
    # Skip ssh_keys: key import requires TFTP server; run 'just push-ansible-key' separately
    ansible-playbook \
        -i $inventory \
        --extra-vars "@$tmp_vars" \
        --extra-vars "@$tmp_conn" \
        --skip-tags ssh_keys \
        $argv \
        "{{scripts_dir}}/hosts/nixable/xswcore/playbook.yml"

    rm -f $tmp_vars $tmp_conn
    echo "Bootstrap complete — run 'just configure-xswcore' for all subsequent runs"

# Import ansible-brocade SSH RSA public key to xswcore via TFTP (one-time setup).
# FastIron 09.x uses 'copy tftp flash <ip> <file> ssh-pub-key-file'; key must be SSH2/RFC4716 format.
# TFTP server: xsvr1 (172.20.1.10), serving /zfs/tftp — see modules/services/tftpd/default.nix
# Prerequisites:
#   1. Generate RSA key: ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible-brocade_key -C "ansible-brocade@xswcore" -N ""
#   2. Store private key in sops: sops {{scripts_dir}}/secrets/ansible-network.yaml
#      Set ansible_private_key to the contents of ~/.ssh/ansible-brocade_key
#   3. Deploy xsvr1 to activate the TFTP service
#   4. Run: just push-ansible-key
push-ansible-key:
    #!/usr/bin/env fish
    set -l secrets "{{scripts_dir}}/secrets/ansible-network.yaml"
    set -l inventory "{{scripts_dir}}/hosts/nixable/xswcore/inventory.yml"
    set -l tmp_vars (mktemp /tmp/net-vars-XXXXXX.yml)
    set -l tmp_conn (mktemp /tmp/net-conn-XXXXXX.yml)
    set -l tmp_key  (mktemp /tmp/net-key-XXXXXX)
    set -l tmp_pub  (mktemp /tmp/net-pub-XXXXXX.pub)
    set -l tmp_ssh2 (mktemp /tmp/net-ssh2-XXXXXX.pub)
    set -l tftp_ip  "172.20.1.10"
    set -l tftp_host "thomas-local@$tftp_ip"
    chmod 600 $tmp_vars $tmp_conn $tmp_key

    if not test -f $secrets
        echo "ERROR: Secrets file not found: $secrets"
        exit 1
    end

    if not sops -d $secrets > $tmp_vars
        rm -f $tmp_vars $tmp_conn $tmp_key $tmp_pub $tmp_ssh2
        echo "ERROR: Failed to decrypt $secrets"
        exit 1
    end

    set -l boot_pass   (sops -d --extract '["vault_user_ansible_password"]' $secrets | string trim)
    set -l enable_pass (sops -d --extract '["ansible_become_password"]' $secrets | string trim)

    # Extract RSA private key and derive SSH2/RFC4716 public key (required by FastIron 09.x)
    if not sops -d --extract '["ansible_private_key"]' $secrets > $tmp_key
        rm -f $tmp_vars $tmp_conn $tmp_key $tmp_pub $tmp_ssh2
        echo "ERROR: Failed to extract ansible_private_key — add it to sops first"
        exit 1
    end
    if not ssh-keygen -y -f $tmp_key > $tmp_pub
        rm -f $tmp_vars $tmp_conn $tmp_key $tmp_pub $tmp_ssh2
        echo "ERROR: Invalid private key — regenerate with:"
        echo "  ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible-brocade_key -C 'ansible-brocade@xswcore' -N ''"
        exit 1
    end
    ssh-keygen -e -f $tmp_pub > $tmp_ssh2
    rm -f $tmp_pub $tmp_key

    # Upload key to xsvr1 TFTP root (/zfs/tftp, writable by wheel group)
    echo "Uploading SSH2 public key to $tftp_host:/zfs/tftp/ansible-brocade.pub..."
    if not scp $tmp_ssh2 "$tftp_host:/zfs/tftp/ansible-brocade.pub"
        rm -f $tmp_vars $tmp_conn $tmp_ssh2
        echo "ERROR: Failed to copy key to $tftp_host — ensure xsvr1 TFTP service is deployed"
        exit 1
    end
    rm -f $tmp_ssh2

    printf "ansible_user: ansible-local\nansible_password: '%s'\nansible_become_password: '%s'\nansible_tftp_ip: %s\n" \
        (string replace --all "'" "''" $boot_pass) \
        (string replace --all "'" "''" $enable_pass) \
        $tftp_ip > $tmp_conn

    echo "Importing SSH public key to xswcore via TFTP from $tftp_ip..."
    set -x ANSIBLE_TERMINAL_PLUGINS "{{scripts_dir}}/hosts/nixable/xswcore/plugins/terminal"
    set -x ANSIBLE_CLICONF_PLUGINS "{{scripts_dir}}/hosts/nixable/xswcore/plugins/cliconf"
    ansible-playbook \
        -i $inventory \
        --extra-vars "@$tmp_vars" \
        --extra-vars "@$tmp_conn" \
        --tags ssh_keys \
        $argv \
        "{{scripts_dir}}/hosts/nixable/xswcore/playbook.yml"
    set -l rc $status

    # Clean up key from TFTP root after import
    ssh $tftp_host "rm -f /zfs/tftp/ansible-brocade.pub" 2>/dev/null
    rm -f $tmp_vars $tmp_conn

    if test $rc -eq 0
        echo "SSH key imported — subsequent runs use: just configure-xswcore"
    else
        exit $rc
    end

# Configure xswcore Brocade ICX-7250 switch via Ansible + sops secrets
# Authenticates as ansible-brocade using RSA key auth (requires just push-ansible-key first).
# Playbook definition (Nix source of truth): nix/hosts/nixable/xswcore/default.nix
# Secrets file: nix/secrets/ansible-network.yaml (shared with other network gear)
#
# Create secrets first: sops {{scripts_dir}}/secrets/ansible-network.yaml
#   Required keys:
#     ansible_private_key: |          # RSA 4096-bit private key for ansible-brocade user
#       -----BEGIN OPENSSH PRIVATE KEY-----
#       ...
#     ansible_become_password: "<enable/super-user password>"
#     vault_snmp_community: "<SNMP RO community string>"
#     vault_user_super_password: "<super user password>"
#     vault_user_ansible_password: "<ansible-brocade switch account password>"
#     vault_user_thomas_password: "<thomas-local password>"
#     vault_user_dog_password: "<dog user password>"
configure-xswcore:
    #!/usr/bin/env fish
    set -l secrets "{{scripts_dir}}/secrets/ansible-network.yaml"
    set -l inventory "{{scripts_dir}}/hosts/nixable/xswcore/inventory.yml"
    set -l tmp_vars (mktemp /tmp/net-vars-XXXXXX.yml)
    set -l tmp_key  (mktemp /tmp/net-key-XXXXXX)
    chmod 600 $tmp_vars $tmp_key

    if not test -f $secrets
        echo "ERROR: Secrets file not found: $secrets"
        echo "Create it with: sops $secrets"
        exit 1
    end

    echo "Decrypting ansible-network secrets..."
    if not sops -d $secrets > $tmp_vars
        rm -f $tmp_vars $tmp_key
        echo "ERROR: Failed to decrypt $secrets"
        exit 1
    end

    if not sops -d --extract '["ansible_private_key"]' $secrets > $tmp_key
        rm -f $tmp_vars $tmp_key
        echo "ERROR: Failed to extract ansible_private_key from $secrets"
        exit 1
    end

    echo "Configuring xswcore..."
    set -x ANSIBLE_TERMINAL_PLUGINS "{{scripts_dir}}/hosts/nixable/xswcore/plugins/terminal"
    set -x ANSIBLE_CLICONF_PLUGINS "{{scripts_dir}}/hosts/nixable/xswcore/plugins/cliconf"
    ansible-playbook \
        -i $inventory \
        --extra-vars "@$tmp_vars" \
        --extra-vars "ansible_private_key_file=$tmp_key" \
        $argv \
        "{{scripts_dir}}/hosts/nixable/xswcore/playbook.yml"

    rm -f $tmp_vars $tmp_key
    echo "xswcore configuration complete"

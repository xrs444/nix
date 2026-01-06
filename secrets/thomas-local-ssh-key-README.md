# Thomas-Local SSH Key Setup

## Overview

This configuration provides passwordless SSH access for the `xrs444` user to log into any machine as the `thomas-local` user using SSH key authentication.

## Components

### 1. SSH Key Pair
- **Public Key**: Added to `thomas-local` user authorized_keys in `modules/users/thomas-local.nix`
- **Private Key**: Stored sops-encrypted in `secrets/thomas-local-ssh-key.yaml`
- **Key Type**: ED25519

### 2. NixOS Configuration

#### thomas-local User (modules/users/thomas-local.nix)
- Has the new public key added to `openssh.authorizedKeys.keys`
- Accepts SSH connections using this key

#### xrs444 User (modules/users/xrs444.nix)
- New module created for NixOS systems
- Configures sops to decrypt the private key to `/home/xrs444/.ssh/thomas-local_key`
- Key is owned by xrs444:xrs444 with mode 0400

#### Home Manager (homemanager/users/xrs444/default.nix)
- SSH configuration added with match blocks for `*.lan` and `thomas-local@*`
- Automatically uses the correct identity file based on platform:
  - NixOS: Uses sops-managed key at `/run/secrets/thomas-local-ssh-key`
  - macOS: Uses `~/.ssh/thomas-local_key`

### 3. macOS Setup

For macOS systems, run the extraction script to get the private key:

```bash
cd /Users/xrs444/Repositories/HomeProd/nix/scripts
./extract-thomas-local-key.sh
```

This will:
1. Decrypt the sops-encrypted key
2. Save it to `~/.ssh/thomas-local_key`
3. Set proper permissions (600)

## Usage

### Automatic (Recommended)

The SSH config is set up to automatically use the thomas-local key for matching hosts:

```bash
# These will automatically use the thomas-local key:
ssh thomas-local@xsvr1.lan
ssh thomas-local@xsvr2.lan
ssh thomas-local@xdash1.lan
```

### Manual

You can also explicitly specify the key:

```bash
ssh -i ~/.ssh/thomas-local_key thomas-local@hostname
```

## Deployment

### NixOS Hosts

1. Deploy the configuration to any NixOS host
2. The sops-nix module will automatically decrypt the private key
3. SSH will work immediately for xrs444 user

### macOS Hosts

1. Run the extraction script (see above)
2. Home Manager will configure SSH to use the key
3. Rebuild Home Manager configuration

## Security

- Private key is encrypted with sops using age
- All configured age keys can decrypt it (see `.sops.yaml`)
- On NixOS, key is owned by xrs444 with restrictive permissions
- On macOS, key is stored in user home directory with mode 600

## Troubleshooting

### Key Not Found

If SSH can't find the key:

```bash
# Check if key exists
ls -la ~/.ssh/thomas-local_key

# Check permissions
chmod 600 ~/.ssh/thomas-local_key
```

### Connection Refused

Verify the public key is in thomas-local's authorized_keys:

```bash
ssh thomas-local@hostname "cat ~/.ssh/authorized_keys"
```

### Sops Decryption Fails

Ensure your age key is configured:

```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# Verify you can decrypt
sops -d secrets/thomas-local-ssh-key.yaml
```

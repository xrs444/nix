# Just Command Runner

This project uses [just](https://github.com/casey/just) as a command runner to simplify common Nix operations.

## Installation

The `just` command is included in the common packages and will be available after rebuilding your system:

```bash
# For NixOS
sudo nixos-rebuild switch --flake .

# For nix-darwin
darwin-rebuild switch --flake .
```

For Bazzite hosts, `just` is automatically installed via the Ansible playbooks.

## Location

The justfile is located at `scripts/justfile`. From the nix repository root, you can run:

```bash
# Run from repository root
just --justfile scripts/justfile --list

# Or create an alias for convenience
alias j='just --justfile scripts/justfile'
j --list
```

## Usage

Run `just` (or `just --list`) to see all available commands:

```bash
cd /path/to/nix
just --justfile scripts/justfile --list
```

## Available Commands

### Build Operations

- `just build-sdimage [host]` - Build SD card image for a host (default: xdash1)
- `just build <host>` - Build a specific host configuration
- `just build-and-cache-all` - Build and cache all hosts using xsvr1 as remote builder

### SD Card Operations

- `just write-sdcard <device>` - Write SD card image to device (e.g., /dev/disk4)
- `just list-disks` - List available disks

### Deployment Operations

- `just deploy-xdash1 <ip> [user]` - Deploy xdash1 using nixos-anywhere (with kexec)
- `just deploy-xdash1-simple <ip> [user]` - Deploy xdash1 using QEMU emulation (no kexec)

### Host Management

- `just new-host <hostname> <platform>` - Create new host configuration (nixos or darwin)

### Validation & Testing

- `just validate` - Validate flake configuration
- `just update` - Update flake inputs
- `just info` - Show flake information
- `just outdated` - Show outdated flake inputs

### Development

- `just dev [shell]` - Enter development shell (default: default)
- `just fmt` - Format nix files

### Cleanup

- `just clean` - Clean build artifacts
- `just gc` - Run garbage collection
- `just optimize` - Optimize nix store
- `just deep-clean` - Full cleanup (clean + gc + optimize)

### SSH & Secrets Management

- `just extract-thomas-local-key` - Extract thomas-local SSH private key from sops
- `just deploy-ssh-key <hostname> [user] [key]` - Deploy SSH key to a Bazzite host for Ansible access

### Nixable/Bazzite Host Management

- `just run-nixable <host>` - Run nixible playbook for a Bazzite host (xdt1-t, xdt2-g, or xdt3-r)

## Examples

```bash
# Build SD image for xdash1
just build-sdimage xdash1

# Write to SD card
just list-disks  # Find your device
just write-sdcard /dev/disk4

# Deploy to remote host
just deploy-xdash1 192.168.1.100 root

# Create new host
just new-host myhost nixos

# Update and validate
just update
just validate

# Clean up
just deep-clean

# Extract SSH key from secrets
just extract-thomas-local-key

# Deploy SSH key to Bazzite host
just deploy-ssh-key xdt1-t
just deploy-ssh-key xdt2-g thomas-local ~/.ssh/id_rsa.pub

# Run nixible playbook
just run-nixable xdt1-t
```

## Migration from Scripts

The justfile has replaced the following scripts (which have been removed):

| Removed Script | Just Command |
| -------------- | ------------ |
| `scripts/write-sdcard.sh` | `just write-sdcard` |
| `scripts/deploy-xdash1.sh` | `just deploy-xdash1` |
| `scripts/deploy-xdash1-simple.sh` | `just deploy-xdash1-simple` |
| `scripts/deploy-xdash1-nokexec.sh` | Removed (use `deploy-xdash1` or `deploy-xdash1-simple`) |
| `scripts/deploy-xdash1-manual.sh` | Removed (use `deploy-xdash1` or `deploy-xdash1-simple`) |
| `scripts/deploy-xdash1-with-kexec-tarball.sh` | Removed (use `deploy-xdash1`) |
| `scripts/build-and-cache-xsvr1-hosts.sh` | `just build-and-cache-all` |
| `scripts/extract-thomas-local-key.sh` | `just extract-thomas-local-key` |
| `hosts/nixable/scripts/deploy-ssh-key.sh` | `just deploy-ssh-key` |

### Remaining Scripts

These scripts remain in `scripts/` for specialized use cases:

- `new-host.sh` - Full-featured host creation with age keys and sops integration (simplified version: `just new-host`)
- `nix-sh.fish` - Fish shell utility
- `init-testing-workflow.fish` - Testing workflow helper

## Platform Availability

- **NixOS hosts**: `just` is installed via `modules/packages-common/default.nix`
- **Darwin hosts**: `just` is installed via `modules/packages-common/default.nix`
- **Bazzite hosts (xdt1-t, xdt2-g, xdt3-r)**: `just` is installed via Ansible playbooks in the nixable host configurations

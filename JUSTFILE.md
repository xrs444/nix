# Just Command Runner

This project uses [just](https://github.com/casey/just) as a command runner to simplify common Nix operations.

## Installation

The `just` command is included in the common packages and will be available after rebuilding your system:

```bash
# For nix-darwin
darwin-rebuild switch --flake .
```

## Usage

Run `just` (or `just --list`) to see all available commands:

```bash
just --list
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
```

## Migration from Scripts

The justfile replaces the following scripts in `scripts/`:

| Old Script | New Just Command |
|------------|------------------|
| `write-sdcard.sh` | `just write-sdcard` |
| `deploy-xdash1.sh` | `just deploy-xdash1` |
| `deploy-xdash1-simple.sh` | `just deploy-xdash1-simple` |
| `build-and-cache-xsvr1-hosts.sh` | `just build-and-cache-all` |
| `new-host.sh` | `just new-host` (simplified) |

The original scripts are kept for reference and advanced use cases.

# Deploying NixOS to xdash1 with nixos-anywhere

This guide explains how to install NixOS on the xdash1 OrangePi device that's currently running DietPi.

## Prerequisites

1. **Network access** to the xdash1 device
2. **SSH access** to the DietPi system (default user is usually `root` or `dietpi`)
3. **Backup** any important data (this will wipe the disk!)

## Deployment Steps

### 1. Prepare the Target System (on DietPi)

SSH into your DietPi system and ensure:
- SSH is enabled and accessible
- You know the root password or have SSH key access
- The system is connected to the network

```bash
# On DietPi, verify SSH is running
systemctl status ssh

# Note the IP address
ip addr show
```

### 2. Run the Deployment Script (from your Mac)

From this repository directory:

```bash
# Make sure you're in the flake directory
cd /Users/xrs444/Repositories/HomeProd/nix

# Run the deployment script with the target IP
./scripts/deploy-xdash1.sh <DIETPI-IP-ADDRESS> root
```

For example:
```bash
./scripts/deploy-xdash1.sh 192.168.1.100 root
```

### 3. What Happens During Deployment

The script will:
1. Install `nixos-anywhere` if not already installed
2. Connect to your DietPi system via SSH
3. Partition and format the SD card using disko configuration
4. Install NixOS using your flake configuration
5. Reboot into NixOS

### 4. Post-Installation

After the system reboots:
- SSH user will be `thomas-local` (configured in your flake)
- The kiosk will auto-start with Firefox in kiosk mode
- WiFi should connect automatically (using sops secrets)

## Troubleshooting

### If deployment fails:

1. **Check SSH access**: Ensure you can SSH into DietPi manually
2. **Check secrets**: Ensure WiFi secrets are properly configured in sops
3. **Check disk device**: The script assumes `/dev/mmcblk0` - verify this on your OrangePi

### Alternative: Manual nixos-anywhere

If the script doesn't work, run nixos-anywhere directly:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#xdash1 \
  --build-on-remote \
  root@<DIETPI-IP>
```

### Testing the Configuration

Before deploying, you can test the build:

```bash
# Build the configuration to check for errors
nix build .#nixosConfigurations.xdash1.config.system.build.toplevel

# Check the disko configuration
nix eval .#nixosConfigurations.xdash1.config.disko.devices --json | jq
```

## Important Notes

- **This will erase all data on the SD card**
- Have console access available in case network configuration fails
- The first boot may take a few minutes to expand partitions and start services
- The kiosk should automatically start Firefox pointing to your Home Assistant instance

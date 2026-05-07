# cmrpi1 - Raspberry Pi 5 AdGuard DNS Server

## Overview

cmrpi1 is a Raspberry Pi 5 running NixOS with AdGuard Home for DNS filtering and ad-blocking.

## Hardware

- **Device**: Raspberry Pi 5
- **Storage**: 256GB NVMe SSD
- **Architecture**: aarch64-linux

## Services

- **AdGuard Home**: DNS server with ad-blocking and filtering
- **AdGuard Sync**: Configuration synchronization for AdGuard Home
- **Tailscale**: VPN connectivity
- **Comin**: Automatic deployment from Git
- **Monitoring**: Prometheus exporters sending metrics to xsvr1
- **Logging**: Promtail sending logs to Loki

## Network Configuration

- **DNS Ports**: TCP/UDP 53
- **Web UI**: TCP 3000 (AdGuard Home)
- **Tailscale**: Mesh VPN

## Roles

- `adguard`: AdGuard Home DNS server
- `tailscale-package`: Tailscale VPN client
- `monitoring-client`: Prometheus exporters and Promtail
- `letsencrypt-host`: TLS certificates

## Deployment

### Initial Setup

1. Build the minimal SD image:
   ```bash
   cd nix
   nix build .#nixosConfigurations.cmrpi1-minimal.config.system.build.sdImage
   ```

2. Flash the image to an SD card:
   ```bash
   sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress
   ```

3. Boot the Raspberry Pi 5 from the SD card

4. After boot, comin will automatically pull and apply the full configuration from Git

### Post-Deployment

1. Update the disk configuration in `disks.nix` with the actual NVMe device ID:
   ```bash
   ssh thomas-local@cmrpi1.lan
   ls -la /dev/disk/by-id/nvme-*
   ```

2. Update `disks.nix` with the correct device ID

3. Run `nixos-rebuild` to apply the disk configuration and migrate to NVMe

## AdGuard Configuration

AdGuard Home web interface will be available at:
- Local: http://cmrpi1.lan:3000
- Tailscale: http://cmrpi1:3000

Initial setup will require creating an admin account through the web UI.

## Notes

- **Determinate Nix**: Installed via base configuration
- **tmux**: Available in system packages
- **Monitoring**: Configured to send metrics to xsvr1 Prometheus
- **Logs**: Sent to Loki for centralized log management
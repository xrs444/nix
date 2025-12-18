# ZFS Replication Setup Guide

## Overview

ZFS replication is now configured using Syncoid (from the Sanoid suite) to replicate ZFS datasets from xsvr1 to xsvr2. This provides incremental, snapshot-based replication with automatic SSH key management.

## Architecture

```
xsvr1 (Source)                    xsvr2 (Target)
─────────────────                 ─────────────────
┌─────────────────┐              ┌─────────────────┐
│  ZFS Datasets   │              │  ZFS Datasets   │
│  ├─ dataset1    │──Syncoid────>│  ├─ dataset1    │
│  ├─ dataset2    │──via SSH────>│  ├─ dataset2    │
│  └─ dataset3    │              │  └─ dataset3    │
└─────────────────┘              └─────────────────┘
      │                                  │
      │ Automated by                     │ Receives via
      │ systemd timer                    │ syncoid user
      └──────────────────────────────────┘
```

## Features

- ✅ Automatic SSH key generation and management
- ✅ Configurable dataset list
- ✅ Scheduled replication via systemd timers
- ✅ Proper ZFS permissions (delegated administration)
- ✅ Connection testing before replication
- ✅ Role-based configuration (source/target)

## Configuration

### Step 1: Configure xsvr1 (Source Host)

Add to `hosts/nixos/xsvr1/default.nix` (or create a separate `replication.nix`):

```nix
{
  # Add the replication source role to hostRoles in flake.nix first
  
  # Enable ZFS replication
  services.zfsReplication = {
    enable = true;
    
    # Specify datasets to replicate
    sourceDatasets = [
      "zpool-xsvr1/data"
      "zpool-xsvr1/backups"
      "zpool-xsvr1/media"
      # Add more datasets as needed
    ];
    
    # Target host (can use hostname, IP, or Tailscale name)
    targetHost = "xsvr2";  # or "192.168.x.x" or "xsvr2.tailnet-name.ts.net"
    
    # How often to replicate (systemd calendar format)
    interval = "hourly";  # or "daily", "*-*-* 02:00:00", etc.
  };
}
```

### Step 2: Update flake.nix roles

Add the replication roles to your host definitions in `flake.nix`:

```nix
hosts = {
  xsvr1 = {
    user = "thomas-local";
    platform = "x86_64-linux";
    type = "nixos";
    roles = [
      "kvm"
      "samba"
      "zfs"
      "zfs-replication-source"  # Add this role
      # ... other roles
    ];
  };
  xsvr2 = {
    user = "thomas-local";
    platform = "x86_64-linux";
    type = "nixos";
    roles = [
      "kvm"
      "samba"
      "zfs"
      "zfs-replication-target"  # Add this role
      # ... other roles
    ];
  };
};
```

### Step 3: Deploy to xsvr1 and Generate SSH Key

```bash
# Deploy configuration to xsvr1
ssh thomas-local@xsvr1
cd /etc/nixos
sudo nixos-rebuild switch --flake .#xsvr1

# The SSH key will be automatically generated on first boot
# To manually trigger key generation or view the public key:
sudo systemctl start syncoid-ssh-keygen
sudo cat /var/lib/syncoid/.ssh/id_ed25519.pub
```

### Step 4: Configure xsvr2 (Target Host)

Add to `hosts/nixos/xsvr2/default.nix`:

```nix
{
  # Enable ZFS replication as target
  services.zfsReplication = {
    enable = true;
    
    # Add the public key from xsvr1
    sshPublicKey = "ssh-ed25519 AAAAC3Nza... syncoid@xsvr1";
  };
}
```

### Step 5: Deploy to xsvr2

```bash
ssh thomas-local@xsvr2
cd /etc/nixos
sudo nixos-rebuild switch --flake .#xsvr2
```

## Usage

### Manual Replication

Run replication manually at any time:

```bash
# On xsvr1
sudo systemctl start zfs-replication
```

### Check Replication Status

```bash
# View last replication run
sudo journalctl -u zfs-replication -n 50

# Check timer status
sudo systemctl status zfs-replication.timer

# View upcoming replication schedule
sudo systemctl list-timers zfs-replication
```

### Verify Replicated Datasets

```bash
# On xsvr2, list replicated datasets
zfs list | grep "zpool-xsvr1"

# Check snapshot history
zfs list -t snapshot | grep "zpool-xsvr1"
```

## Configuration Options

### Replication Intervals

You can use any systemd calendar format:

```nix
interval = "hourly";           # Every hour
interval = "daily";            # Once per day
interval = "*-*-* 02:00:00";   # Daily at 2 AM
interval = "*-*-* 00/4:00:00"; # Every 4 hours
interval = "Mon 09:00:00";     # Every Monday at 9 AM
```

### Multiple Source Datasets

Replicate as many datasets as needed:

```nix
sourceDatasets = [
  "zpool-xsvr1/data"
  "zpool-xsvr1/backups"
  "zpool-xsvr1/media/movies"
  "zpool-xsvr1/media/tvshows"
  "zpool-xsvr1/vms"
];
```

### Advanced SSH Configuration

By default, Syncoid uses the generated SSH key at `/var/lib/syncoid/.ssh/id_ed25519`. If you need custom SSH options, you can modify the `zfs-replication` service after deployment.

## Monitoring

### Add Prometheus Alerts

You can add alerts for replication failures in `modules/services/monitoring/prometheus.nix`:

```nix
{
  alert = "ZFSReplicationFailed";
  expr = "time() - node_systemd_unit_state_start_time_seconds{name=\"zfs-replication.service\",state=\"failed\"} < 3600";
  for = "5m";
  labels = { severity = "warning"; };
  annotations = {
    summary = "ZFS replication failed on {{ $labels.instance }}";
    description = "ZFS replication service has failed within the last hour.";
  };
}
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection manually
sudo -u syncoid ssh -i /var/lib/syncoid/.ssh/id_ed25519 syncoid@xsvr2

# Check authorized keys on target
ssh thomas-local@xsvr2
sudo cat /var/lib/syncoid/.ssh/authorized_keys
```

### Permission Issues

```bash
# On source (xsvr1), verify ZFS permissions
sudo zfs allow zpool-xsvr1/data

# On target (xsvr2), verify ZFS permissions
sudo zfs allow zpool-xsvr2
```

### View Detailed Logs

```bash
# On xsvr1, view replication logs with full output
sudo journalctl -u zfs-replication -f

# Check for SSH issues
sudo journalctl -u sshd | grep syncoid
```

### Manually Run Syncoid

```bash
# On xsvr1, test syncoid manually as the syncoid user
sudo -u syncoid syncoid \
  --no-privilege-elevation \
  --sshkey /var/lib/syncoid/.ssh/id_ed25519 \
  zpool-xsvr1/data \
  syncoid@xsvr2:zpool-xsvr1/data
```

## Recovery and Rollback

### Restore from Replicated Dataset

If you need to restore data from xsvr2:

```bash
# On xsvr2, send dataset back to xsvr1
sudo syncoid zpool-xsvr1/data thomas-local@xsvr1:zpool-xsvr1/data-restored
```

### Roll Back to Previous Snapshot

```bash
# List snapshots
zfs list -t snapshot zpool-xsvr1/data

# Rollback to specific snapshot
sudo zfs rollback zpool-xsvr1/data@autosnap_2025-12-18_14:00:00_hourly
```

## Security Considerations

- SSH keys are stored in `/var/lib/syncoid/.ssh/` with proper permissions (600)
- The `syncoid` user has minimal ZFS permissions (only what's needed for replication)
- SSH connections use key-based authentication only (no passwords)
- Target host only accepts connections from authorized source keys
- Consider using Tailscale or VPN for encrypted transport over the internet

## Performance Tuning

### Bandwidth Limiting

If replication uses too much bandwidth, you can add mbuffer settings:

```bash
# Modify the systemd service to add bandwidth limit
# Edit: systemd.services.zfs-replication.script
# Add to syncoid command: --mbuffer-size 256M --mbuffer-rate 50M
```

### Compression

Syncoid automatically uses compression for transfers. ZFS datasets with `compression=lz4` will transfer faster.

## Next Steps

1. Monitor first replication run
2. Verify snapshots on target
3. Set up Prometheus monitoring
4. Document recovery procedures
5. Test restoration process

## Files

- Module: `modules/services/zfs/replication.nix`
- Main ZFS module: `modules/services/zfs/default.nix`
- xsvr1 config: `hosts/nixos/xsvr1/`
- xsvr2 config: `hosts/nixos/xsvr2/`


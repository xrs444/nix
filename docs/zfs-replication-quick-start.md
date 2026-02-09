# ZFS Replication Quick Start

## What You Need

1. xsvr1 (source) and xsvr2 (target) both with ZFS
2. Network connectivity between hosts
3. List of datasets you want to replicate

## Quick Setup (5 Steps)

### 1. Update flake.nix

Add replication roles to both hosts in `nix/flake.nix`:

```nix
xsvr1 = {
  # ... existing config ...
  roles = [
    # ... existing roles ...
    "zfs-replication-source"  # ADD THIS
  ];
};

xsvr2 = {
  # ... existing config ...
  roles = [
    # ... existing roles ...
    "zfs-replication-target"  # ADD THIS
  ];
};
```

### 2. Configure xsvr1

Create `nix/hosts/nixos/xsvr1/replication.nix` (or add to `default.nix`):

```nix
{
  services.zfsReplication = {
    enable = true;
    sourceDatasets = [
      "zpool-xsvr1/data"          # CHANGE TO YOUR DATASETS
      "zpool-xsvr1/backups"       # ADD/REMOVE AS NEEDED
    ];
    targetHost = "xsvr2";         # OR USE IP/TAILSCALE NAME
    interval = "hourly";
  };
}
```

If creating separate file, import it in `default.nix`:
```nix
imports = [
  # ... existing imports ...
  ./replication.nix
];
```

### 3. Deploy xsvr1 & Get SSH Key

```bash
# Deploy to xsvr1
ssh thomas-local@xsvr1
cd /etc/nixos
sudo nixos-rebuild switch --flake .#xsvr1

# Get the SSH public key
sudo cat /var/lib/syncoid/.ssh/id_ed25519.pub
# Copy this key for next step
```

### 4. Configure xsvr2

Create `nix/hosts/nixos/xsvr2/replication.nix` (or add to `default.nix`):

```nix
{
  services.zfsReplication = {
    enable = true;
    sshPublicKey = "ssh-ed25519 AAAAC3Nza... syncoid@xsvr1";  # PASTE KEY FROM STEP 3
  };
}
```

### 5. Deploy xsvr2 & Test

```bash
# Deploy to xsvr2
ssh thomas-local@xsvr2
cd /etc/nixos
sudo nixos-rebuild switch --flake .#xsvr2

# Test replication (from xsvr1)
ssh thomas-local@xsvr1
sudo systemctl start zfs-replication

# Check status
sudo journalctl -u zfs-replication -f
```

## Verify Replication

On xsvr2:
```bash
# See replicated datasets
zfs list | grep xsvr1

# See snapshots
zfs list -t snapshot | grep xsvr1
```

## Check Automatic Replication

```bash
# View timer status
sudo systemctl status zfs-replication.timer

# See next run time
sudo systemctl list-timers zfs-replication
```

## Common Issues

**SSH Connection Fails**
- Check network connectivity: `ping xsvr2`
- Verify SSH key was copied correctly
- Check firewall rules

**Permission Denied on ZFS**
- Permissions are automatically granted by the module
- If issues persist: `sudo zfs allow zpool-xsvr1`

**Timer Not Running**
- Check timer is enabled: `sudo systemctl status zfs-replication.timer`
- Manually enable: `sudo systemctl enable zfs-replication.timer`

## Need Help?

See detailed documentation: `nix/modules/services/zfs/readme-replication.md`


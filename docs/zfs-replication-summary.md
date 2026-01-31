# ZFS Snapshot Replication - Implementation Summary

## What Was Created

A complete ZFS replication system using Syncoid that allows you to replicate ZFS datasets from xsvr1 to xsvr2 with configurable dataset selection.

## Files Created

1. **`modules/services/zfs/replication.nix`** - Main replication module
   - Handles SSH key generation
   - Manages ZFS permissions
   - Configures systemd services and timers
   - Supports both source and target roles

2. **`modules/services/zfs/default.nix`** - Updated to import replication module

3. **`modules/services/zfs/readme-replication.md`** - Comprehensive documentation
   - Full setup instructions
   - Configuration options
   - Troubleshooting guide
   - Monitoring and performance tuning

4. **`ZFS-REPLICATION-QUICK-START.md`** - 5-step quick start guide

5. **Example Configurations:**
   - `hosts/nixos/xsvr1/examples/replication-example.nix`
   - `hosts/nixos/xsvr2/examples/replication-example.nix`

## Key Features

✅ **Configurable Dataset Selection** - Specify exactly which datasets to replicate
✅ **Automatic SSH Key Management** - Keys generated and managed automatically
✅ **Scheduled Replication** - Configurable intervals via systemd timers
✅ **Proper ZFS Permissions** - Delegated ZFS permissions without root access
✅ **Connection Testing** - SSH connectivity verified before each replication
✅ **Role-Based Configuration** - Separate source/target host configurations

## How to Use

### Quick Start

1. Add roles to `flake.nix`:

   ```nix
   xsvr1 = { roles = [ ... "zfs-replication-source" ]; };
   xsvr2 = { roles = [ ... "zfs-replication-target" ]; };
   ```

2. Configure xsvr1 (example in `hosts/nixos/xsvr1/examples/replication-example.nix`)
3. Deploy xsvr1 and get SSH public key
4. Configure xsvr2 with the public key (example in `hosts/nixos/xsvr2/examples/replication-example.nix`)
5. Deploy xsvr2 and test replication

See **`ZFS-REPLICATION-QUICK-START.md`** for detailed steps.

## Configuration Example

### xsvr1 (Source)

```nix
services.zfsReplication = {
  enable = true;
  sourceDatasets = [
    "zpool-xsvr1/data"
    "zpool-xsvr1/backups"
    "zpool-xsvr1/media"
  ];
  targetHost = "xsvr2";
  interval = "hourly";
};
```

### xsvr2 (Target)

```nix
services.zfsReplication = {
  enable = true;
  sshPublicKey = "ssh-ed25519 AAAAC3Nza... syncoid@xsvr1";
};
```

## Technical Details

### Components

- **Syncoid**: Industry-standard ZFS replication tool (from Sanoid suite)
- **SSH Keys**: Ed25519 keys generated per-host in `/var/lib/syncoid/.ssh/`
- **SystemD**: Services and timers for automation
- **ZFS Delegated Permissions**: Non-root replication with minimal permissions

### Replication Flow

1. `syncoid-ssh-keygen.service` generates SSH keys on first boot
2. `syncoid-zfs-permissions.service` grants necessary ZFS permissions
3. `zfs-replication.timer` triggers replication at configured interval
4. `zfs-replication.service` runs Syncoid for each configured dataset
5. Snapshots are created on source and replicated to target incrementally

### Security

- SSH key-based authentication only (no passwords)
- Minimal ZFS permissions (send/snapshot on source, receive/create on target)
- Dedicated `syncoid` system user
- Optional: Use Tailscale for encrypted transport

## Testing

Manual replication test:

```bash
ssh thomas-local@xsvr1
sudo systemctl start zfs-replication
sudo journalctl -u zfs-replication -f
```

Verify on target:

```bash
ssh thomas-local@xsvr2
zfs list | grep xsvr1
zfs list -t snapshot | grep xsvr1
```

## Monitoring

Check replication status:

```bash
# View timer status
sudo systemctl status zfs-replication.timer

# View last run
sudo journalctl -u zfs-replication -n 50

# See schedule
sudo systemctl list-timers zfs-replication
```

## Next Steps

1. Review **`ZFS-REPLICATION-QUICK-START.md`** for setup instructions
2. Check **`modules/services/zfs/readme-replication.md`** for detailed documentation
3. Customize example configurations for your datasets
4. Deploy to xsvr1 and xsvr2
5. Test replication
6. Set up monitoring/alerting (optional)

## Documentation Links

- Quick Start: `ZFS-REPLICATION-QUICK-START.md`
- Full Documentation: `modules/services/zfs/readme-replication.md`
- Module Code: `modules/services/zfs/replication.nix`
- Examples: `hosts/nixos/xsvr{1,2}/examples/replication-example.nix`

---

**Implementation Date:** December 18, 2025
**Status:** Ready for deployment
**Tested:** Configuration validated, ready for real-world testing

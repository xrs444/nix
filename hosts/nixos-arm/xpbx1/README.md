# xpbx1 - Asterisk PBX on Raspberry Pi 3B

## Overview

xpbx1 is a NixOS-based Asterisk PBX server running on a Raspberry Pi 3B. It will be configured to use DPMA (Digium Phone Module for Asterisk) to manage Sangoma P315 phones.

## Hardware

- **Device**: Raspberry Pi 3B
- **Storage**: MicroSD card
- **Network**: Ethernet (eth0)
- **Phones**: Sangoma P315 (configured via DPMA)

## Initial Setup

### 1. Build SD Card Image

From the nix directory, build the minimal SD card image:

```bash
cd /Users/xrs444/Repositories/HomeProd/nix
nix build .#nixosConfigurations.xpbx1-minimal.config.system.build.sdImage
```

### 2. Write Image to SD Card

Find your SD card device (e.g., `/dev/disk4`):

```bash
diskutil list
```

Write the image:

```bash
just write-sdcard /dev/diskN
```

Or manually:

```bash
sudo dd if=./result/sd-image/xpbx1-sd-image.img of=/dev/rdiskN bs=4m status=progress
```

### 3. First Boot

1. Insert SD card into Raspberry Pi 3B
2. Connect ethernet cable
3. Power on the device
4. Find the IP address (check your DHCP server/router)
5. SSH as root with password "nixos":

```bash
ssh root@<ip-address>
```

6. **IMPORTANT**: Change the root password immediately:

```bash
passwd
```

### 4. Generate Host Age Key for SOPS

Generate the host's age key for secrets management:

```bash
mkdir -p /var/lib/private/sops/age
age-keygen -o /var/lib/private/sops/age/keys.txt
age-keygen -y /var/lib/private/sops/age/keys.txt
```

Add the public key to `.sops.yaml` in the nix repository.

## Asterisk Configuration

### Current State

The basic Asterisk configuration is in place with:
- PJSIP transport on UDP port 5060
- RTP ports 10000-20000
- Basic modules loaded
- Placeholder configuration files

### Next Steps - DPMA Configuration

DPMA (Digium Phone Module for Asterisk) configuration for Sangoma P315 phones needs to be added. This includes:

1. **Install DPMA Module**
   - DPMA is proprietary and may need to be added to nixpkgs or loaded manually
   - Check if available in nixpkgs or use `extraModules` in Asterisk config

2. **Configure dpma.conf**
   - Add to `services.asterisk.confFiles` in `default.nix`
   - Set up network settings, firmware location, and phone provisioning

3. **Configure res_digium_phone.conf**
   - Phone-specific settings
   - Button mappings
   - Display settings

4. **Add Extension Configuration**
   - Update `pjsip.conf` with endpoint configurations
   - Update `extensions.conf` with dialplan
   - Configure voicemail if needed

### Example DPMA Configuration Structure

```nix
services.asterisk.confFiles."dpma.conf" = ''
  [general]
  network = 192.168.x.x/24
  port = 2000

  [default-phone](!)
  type = D70
  line1_enabled = yes

  [phone1](default-phone)
  mac = AA:BB:CC:DD:EE:FF
  line1_exten = 100
  line1_label = Extension 100
'';
```

## Network Ports

The following ports are open for Asterisk:

- **TCP 5060**: SIP signaling
- **TCP 8088**: Asterisk HTTP/WebSocket (for management)
- **UDP 5060**: SIP signaling
- **UDP 10000-20000**: RTP media streams

## Monitoring & Logging

xpbx1 is configured with full observability via the `"monitoring-client"` role:

### Logs (Loki)
- **Promtail** ships logs to Loki at https://loki.xrs444.net
- **Systemd Journal**: All asterisk.service logs automatically captured
- **Asterisk Log Files**: `/var/log/asterisk/*.log` explicitly monitored
- View logs in Grafana at https://grafana.xrs444.net

### Metrics (Prometheus)
- **node_exporter** (port 9100): System metrics (CPU, memory, disk, network)
- **smartctl_exporter** (port 9633): Disk health metrics
- Metrics scraped by Prometheus at https://prometheus.xrs444.net
- View dashboards in Grafana at https://grafana.xrs444.net

### Optional: Asterisk-Specific Metrics
For detailed Asterisk call metrics, consider adding an Asterisk Prometheus exporter:
- [gonicus/asterisk-prometheus-exporter](https://github.com/gonicus/asterisk-prometheus-exporter) - AMI-based exporter
- [pchero/asterisk-exporter](https://github.com/pchero/asterisk-exporter) - Tested with Asterisk 18
- See [Asterisk Community discussion](https://community.asterisk.org/t/monitoring-asterisk-with-prometheus/94325) for setup guides

## Useful Commands

### Check Asterisk Status

```bash
systemctl status asterisk
```

### View Asterisk Logs

```bash
journalctl -u asterisk -f
```

### Asterisk CLI

```bash
asterisk -rvvv
```

### Rebuild Configuration

After making changes to the NixOS configuration:

```bash
nixos-rebuild switch --flake github:xrs444/HomeProd/nix#xpbx1
```

Or from local checkout:

```bash
nixos-rebuild switch --flake /path/to/HomeProd/nix#xpbx1
```

## Resources

- [NixOS Asterisk Module Documentation](https://github.com/NixOS/nixpkgs/blob/release-25.11/nixos/modules/services/networking/asterisk.nix)
- [Asterisk PJSIP Configuration](https://wiki.asterisk.org/wiki/display/AST/Configuring+res_pjsip)
- [Sangoma DPMA Documentation](https://www.sangoma.com/support/documentation/)
- [MyNixOS Asterisk Options](https://mynixos.com/nixpkgs/option/services.asterisk.confFiles)

## Extension List

All extensions have been configured in the system:

| Extension | Location | Device Type |
|-----------|----------|-------------|
| 801 | Home Assistant | SIP Integration |
| 810 | RF Cabinet | Sangoma P315 |
| 811 | Greyson's Room | Sangoma P315 |
| 812 | Rowan's Room | Sangoma P315 |
| 813 | Garage | Sangoma P315 |
| 814 | Rack | Sangoma P315 |
| 815 | Thomas' Desk | Grandstream H802 (port 1) |
| 816 | Samantha's Desk | Grandstream H802 (port 2) |
| 817 | xstarfish | Polycom SoundStation IP 7000 |
| 818 | Master Bedroom | Grandstream H801 |

## Configuration Steps Required

### 1. Update SIP Passwords

In [default.nix](default.nix), change all `CHANGE_ME_*` passwords to secure passwords:

```nix
password = CHANGE_ME_801  # Change to actual password
```

**IMPORTANT**: Use strong, unique passwords for each extension!

### 2. Network Configuration

The PBX is configured for the VoIP network:
- **PBX IP**: 172.18.6.1/24
- **DPMA Network**: 172.18.6.0/24
- **Phone Range**: 172.18.6.x

All phones and devices should be on this subnet to communicate with the PBX.

### 3. Add Sangoma P315 MAC Addresses

Once you have the physical phones, find their MAC addresses and update in [default.nix](default.nix):

```nix
[810](default-p315)
mac = 00:00:00:00:00:00  # Replace with actual MAC
```

To find a phone's MAC address:
- Check the label on the bottom of the phone
- Or boot the phone and press Menu → Settings → Status → Network
- Or check your DHCP server logs

### 4. Configure Grandstream ATAs

For the H801 and H802 devices, log into their web interface and configure:

**Account Settings:**
- SIP Server: `xpbx1.xrs444.net` (or IP address)
- SIP User ID: Extension number (815, 816, 817, or 818)
- Authenticate ID: Same as User ID
- Authenticate Password: The password you set in step 1
- Name: Display name from the table above

**Network Settings:**
- Ensure DHCP or static IP is configured
- DNS should resolve `xpbx1.xrs444.net`

**For H802 (2-port):**
- Configure Account 1 for extension 815 (Thomas' Desk)
- Configure Account 2 for extension 816 (Samantha's Desk)

## Phone Provisioning

### Sangoma P315 (DPMA Auto-Provisioning)

The P315 phones will auto-provision via DPMA:

1. **Connect phone to network** (same subnet as xpbx1)
2. **Boot the phone** - it will request DHCP
3. **DPMA discovery** - phone will find the PBX via multicast
4. **Auto-configure** - phone downloads config from port 2000
5. **Ready to use** - phone registers and BLF lights activate

**Troubleshooting:**
- Ensure phones are on same network as DPMA `network` setting
- Check firewall allows UDP port 2000
- Verify MAC address is correct in config
- Check Asterisk logs: `journalctl -u asterisk -f`

### Grandstream Devices (Manual Configuration)

ATAs must be manually configured via web interface:

1. Find the device IP (check DHCP leases or use phone's menu)
2. Browse to `http://<device-ip>`
3. Login (default: admin/admin)
4. Configure SIP account as described above
5. Save and reboot

## BLF (Busy Lamp Field) Configuration

Each Sangoma P315 has 4 BLF buttons configured to monitor other extensions:

- **810 (RF Cabinet)**: Monitors 811, 812, 815, 816
- **811 (Greyson)**: Monitors 812, 815, 816, 810
- **812 (Rowan)**: Monitors 811, 815, 816, 810
- **813 (Garage)**: Monitors 815, 816, 818, 810
- **814 (Rack)**: Monitors 810, 815, 816, 801

BLF lights show:
- **Green**: Extension idle
- **Red**: Extension in use
- **Press button**: Speed dial to that extension

## Testing

### Test Extension Registration

```bash
asterisk -rx "pjsip show endpoints"
```

Should show all extensions with status "Avail" or "Unavail"

### Test Call Between Extensions

1. Pick up phone at extension 815
2. Dial 816
3. Phone at 816 should ring
4. Answer and verify audio both ways

### Test DPMA Provisioning

```bash
asterisk -rx "dpma show devices"
```

Should show all Sangoma P315 phones with their MAC addresses and status

## TODO

- [ ] Update all CHANGE_ME passwords to secure passwords
- [ ] Update DPMA network range to match actual LAN
- [ ] Add Sangoma P315 MAC addresses when phones arrive
- [ ] Configure Grandstream H801 for extension 818
- [ ] Configure Grandstream H802 for extensions 815 and 816
- [ ] Configure Home Assistant SIP integration for extension 801
- [ ] Configure xstarfish device for extension 817
- [ ] Set up voicemail if needed
- [ ] Configure backup/restore for Asterisk data
- [ ] Test all extensions for registration and call routing
- [ ] Verify BLF functionality on P315 phones

# SNMP Exporter Setup Guide

The SNMP exporter is currently disabled due to configuration format changes. This guide explains how to re-enable it.

## Prerequisites

- SNMP-enabled network devices (switches, APs, firewalls)
- SNMP community strings or v3 credentials
- MIBs for your specific devices (optional but recommended)

## Steps to Re-enable

### 1. Generate SNMP Exporter Configuration

The SNMP exporter requires a generated configuration file. You can either:

#### Option A: Use Pre-built Modules (Simple)

Use the default modules that come with the exporter:

```nix
services.prometheus.exporters.snmp = {
  enable = true;
  port = 9116;
  listenAddress = "0.0.0.0";
  openFirewall = false;
  # Use default configuration (basic if_mib support)
  configurationPath = null;
};
```

#### Option B: Generate Custom Configuration (Recommended)

For device-specific metrics, generate a custom config:

```bash
# Clone the snmp_exporter repository
git clone https://github.com/prometheus/snmp_exporter.git
cd snmp_exporter/generator

# Install dependencies
sudo apt-get install unzip build-essential libsnmp-dev  # Debian/Ubuntu
# or
sudo dnf install gcc gcc-c++ make net-snmp net-snmp-utils net-snmp-devel  # Fedora/RHEL

# Edit generator.yml to include your device modules
# Example modules for common devices:
# - if_mib (standard interface metrics)
# - ddwrt (DD-WRT routers)
# - ubiquiti_airmax (Ubiquiti devices)

# Generate the configuration
make generator
./generator generate

# Copy the generated snmp.yml
cp snmp.yml /path/to/nix/modules/services/monitoring/snmp-config.yml
```

Then reference it in your NixOS config:

```nix
services.prometheus.exporters.snmp = {
  enable = true;
  port = 9116;
  listenAddress = "0.0.0.0";
  openFirewall = false;
  configurationPath = ./snmp-config.yml;
};
```

### 2. Update exporters.nix

In `/nix/modules/services/monitoring/exporters.nix`, change:

```nix
services.prometheus.exporters.snmp = lib.mkIf isMonitoringServer {
  enable = false;  # <-- Change to true
  port = 9116;
  listenAddress = "0.0.0.0";
  openFirewall = false;
};
```

### 3. Configure Prometheus Scrape Jobs

In `/nix/modules/services/monitoring/prometheus.nix`, uncomment and configure the SNMP scrape jobs:

```nix
# Brocade switches
{
  job_name = "snmp-brocade";
  scrape_interval = "60s";
  static_configs = [
    {
      targets = [
        "192.168.1.10"  # brocade-switch-1
        "192.168.1.11"  # brocade-switch-2
      ];
    }
  ];
  metrics_path = "/snmp";
  params = {
    module = [ "if_mib" ];  # or custom module name
  };
  relabel_configs = [
    {
      source_labels = [ "__address__" ];
      target_label = "__param_target";
    }
    {
      source_labels = [ "__param_target" ];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement = "localhost:9116";
    }
  ];
}
```

### 4. Device-Specific Configuration

#### Brocade Switches
- Module: `if_mib` (standard) or generate custom with Brocade MIBs
- SNMP version: v2c or v3
- Community string: Configure in your switch

#### Omada Access Points
- Module: `if_mib` (basic) or `ubiquiti_airmax` (if compatible)
- SNMP version: v2c
- Enable SNMP in Omada controller

#### Firewalla
- Module: `if_mib`
- SNMP version: v2c
- Enable SNMP in Firewalla settings

### 5. Testing

After configuration, test SNMP queries:

```bash
# Test SNMP connectivity
snmpwalk -v2c -c public <device-ip> system

# Test the exporter
curl http://localhost:9116/snmp?target=192.168.1.10&module=if_mib

# Check Prometheus targets
# Navigate to http://xsvr1:9090/targets and verify SNMP jobs are UP
```

## Example generator.yml

```yaml
modules:
  # Standard interface MIB
  if_mib:
    walk:
      - sysUpTime
      - interfaces
      - ifXTable
    lookups:
      - source_indexes: [ifIndex]
        lookup: ifAlias
      - source_indexes: [ifIndex]
        lookup: ifDescr
      - source_indexes: [ifIndex]
        lookup: ifName
    overrides:
      ifAlias:
        ignore: true
      ifDescr:
        ignore: true
      ifName:
        ignore: true
      ifType:
        type: EnumAsInfo

  # Brocade-specific (if you have Brocade MIBs)
  brocade:
    walk:
      - sysUpTime
      - interfaces
      - ifXTable
      - 1.3.6.1.4.1.1991  # Brocade enterprise OID
    lookups:
      - source_indexes: [ifIndex]
        lookup: ifDescr
```

## Troubleshooting

### Exporter fails to start
- Check configuration syntax: `promtool check config /etc/prometheus/snmp.yml`
- Verify SNMP exporter binary is available: `which snmp_exporter`

### No metrics returned
- Verify device SNMP is enabled
- Check SNMP version and community string match
- Test with `snmpwalk` first
- Check firewall rules on device

### Metrics incomplete
- Generate custom config with device-specific MIBs
- Use `snmpwalk` to identify available OIDs
- Update generator.yml with appropriate walks

## References

- [SNMP Exporter GitHub](https://github.com/prometheus/snmp_exporter)
- [Generator Documentation](https://github.com/prometheus/snmp_exporter/tree/main/generator)
- [Default Modules](https://github.com/prometheus/snmp_exporter/blob/main/snmp.yml)

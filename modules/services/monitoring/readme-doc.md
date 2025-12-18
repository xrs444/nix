# Monitoring Module

Role-based monitoring configuration using Prometheus and Grafana.

## Architecture

- **Prometheus Server**: Runs on monitoring server host, scrapes all targets
- **Grafana**: Visualization and dashboarding, provisioned with Prometheus datasource
- **Exporters**: Run on all monitored hosts (clients and server)
  - `node_exporter`: System metrics (CPU, memory, disk, network)
  - `zfs_exporter`: ZFS pool metrics (only on xsvr1, xsvr2)

## Host Roles

Add to `flake.nix` host configuration:

### Monitoring Server
```nix
hostRoles = [ "monitoring-server" ];
```
Enables: Prometheus server, Grafana, exporters

### Monitoring Client
```nix
hostRoles = [ "monitoring-client" ];
```
Enables: Exporters only (node_exporter, zfs_exporter if applicable)

## Network Configuration

- All services bind to `0.0.0.0` but firewall rules limit access to Tailscale interface
- Ports opened on `tailscale0` interface:
  - `9090`: Prometheus server
  - `3000`: Grafana web UI
  - `9100`: node_exporter (all hosts)
  - `9134`: zfs_exporter (ZFS hosts only)

## Access

Once deployed on the monitoring server (e.g., xsvr1):

- **Prometheus**: `http://xsvr1:9090`
- **Grafana**: `http://xsvr1:3000`
  - Default user: `admin`
  - Password: Set via Grafana's environment file (TODO: secrets management)

## Metrics Collected

### Node Exporter (All Hosts)
- CPU usage, load average
- Memory and swap usage
- Disk I/O and space
- Network traffic
- Systemd units status
- Process counts

### ZFS Exporter (xsvr1, xsvr2)
- Pool health and status
- Dataset usage
- ARC statistics
- I/O statistics
- Scrub status

## TODO

- [ ] Add alerting rules (disk space, service down, etc.)
- [ ] Configure Alertmanager
- [ ] Provision Grafana dashboards
- [ ] Secrets management for Grafana admin password
- [ ] Add Kubernetes metrics scraping (Talos VMs)
- [ ] Consider adding `smartmon_exporter` for disk health
- [ ] Add `systemd_exporter` for detailed service metrics
- [ ] Configure long-term storage retention strategy

## Adding New Hosts

1. Add hostname to `allHosts` in `prometheus.nix`
2. If host has ZFS, add to `zfsHosts` as well
3. Add `monitoring-client` role to host in `flake.nix`
4. Rebuild host configuration

## Customization

### Change Scrape Interval
Edit `globalConfig.scrape_interval` in `prometheus.nix`

### Add Custom Exporters
Add exporter configuration to `exporters.nix` and update firewall rules

### Retention Period
Edit `retentionTime` in `prometheus.nix` (default: 30 days)

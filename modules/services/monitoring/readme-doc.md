# Monitoring Module

Role-based Prometheus exporters, scraped by the live Kubernetes
kube-prometheus-stack (`flux/apps/observability/monitoring/`) via static
targets in its `prometheus-additional-scrape-configs` secret. There is no
Prometheus server or Grafana running on the NixOS side — both used to live
here (`prometheus.nix`, `grafana.nix`) but were decommissioned once the k8s
stack took over dashboards/alerting/Grafana entirely.

## Host Roles

Add to `flake.nix` host configuration:

```nix
hostRoles = [ "monitoring-client" ];   # or "monitoring-server"
```

Both roles enable the same exporters today (`enableExporters = isMonitoringServer
|| isMonitoringClient` in `exporters.nix`) — the distinction is now vestigial,
kept mainly because `monitoring-server` still identifies xsvr1 in a few other
unrelated modules.

## Exporters (exporters.nix)

- `node_exporter` (:9100) — all monitoring hosts
- `zfs_exporter` (:9134) — xsvr1, xsvr2
- `prometheus-libvirt-exporter` (:9177, custom systemd unit) — xsvr1, xsvr2, xsvr3
- `smartctl_exporter` (:9633) — all monitoring hosts
- `bind_exporter` (:9119) — currently disabled (`hasBIND = false`)

Firewall ports for these are opened on all interfaces (not Tailscale-scoped —
k8s pod traffic needs to reach them too).

## Logs (promtail.nix)

Despite the filename, this ships systemd-journal logs to the k8s Loki app
(`https://loki.xrs444.net/loki/api/v1/push`) via Grafana Alloy, not promtail
(promtail was removed in NixOS 26.05). Independent of everything above.

## Adding a New Host

1. Add `monitoring-client` to the host's `hostRoles` in `flake.nix`.
2. If the k8s Prometheus should scrape it, add the host to the relevant
   `static_configs` target list in
   `flux/apps/observability/monitoring/sealedsecret-additional-scrape-configs.yaml`
   (job `node`, plus `zfs`/`smartctl`/`libvirt` as applicable).
3. Rebuild.

## SNMP / blackbox / pushgateway

These are no longer configured on the NixOS side. Equivalent Deployments run
in-cluster: `flux/apps/observability/monitoring/deployment-{blackbox,snmp-exporter,pushgateway}.yaml`.

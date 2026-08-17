# Summary: Imports the monitoring-client/server exporters (node/zfs/libvirt/
# smartctl) and the Loki log shipper. The Prometheus server + Grafana that
# used to run here were decommissioned in favor of the k8s kube-prometheus-stack
# (flux/apps/observability/monitoring/), which now scrapes these exporters
# directly via static targets.
{ ... }:
{
  imports = [
    ./exporters.nix
    ./promtail.nix
  ];
}

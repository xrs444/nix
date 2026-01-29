# Summary: Main monitoring module - imports Prometheus, Grafana, and exporters based on host roles.
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  # Role-based configuration
  isMonitoringServer = lib.elem "monitoring-server" hostRoles;
  isMonitoringClient = lib.elem "monitoring-client" hostRoles;

  # Enable monitoring if either role is present
  enableMonitoring = isMonitoringServer || isMonitoringClient;
in
{
  imports = [
    ./exporters.nix
    ./prometheus.nix
    ./grafana.nix
    ./promtail.nix
  ];

  config = lib.mkIf enableMonitoring {
    # Open firewall ports for monitoring services
    networking.firewall = lib.mkIf isMonitoringServer {
      allowedTCPPorts = [
        9090 # Prometheus
        9093 # Alertmanager
        3000 # Grafana
      ];
    };
  };
}

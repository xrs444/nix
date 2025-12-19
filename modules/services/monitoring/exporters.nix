# Summary: Prometheus exporters configuration - node_exporter and zfs_exporter.
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  isMonitoringServer = lib.elem "monitoring-server" hostRoles;
  isMonitoringClient = lib.elem "monitoring-client" hostRoles;
  enableExporters = isMonitoringServer || isMonitoringClient;

  # Detect if host has ZFS
  hasZFS = builtins.elem hostname [
    "xsvr1"
    "xsvr2"
  ];
in
{
  config = lib.mkIf enableExporters {
    # Node exporter - basic system metrics
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = "0.0.0.0"; # Listen on all interfaces
      enabledCollectors = [
        "systemd"
        "processes"
        "interrupts"
      ];
      openFirewall = false; # We'll use Tailscale interface rules
    };

    # ZFS exporter - for hosts with ZFS pools
    services.prometheus.exporters.zfs = lib.mkIf hasZFS {
      enable = true;
      port = 9134;
      listenAddress = "0.0.0.0";
      # pools = null; # Monitor all pools by default
      openFirewall = false;
    };

    # SNMP exporter - for network devices (only on monitoring server)
    # SNMP exporter disabled temporarily due to config format changes
    # TODO: Re-enable after generating proper config with snmp_exporter generator
    # See: https://github.com/prometheus/snmp_exporter/tree/main/generator
    services.prometheus.exporters.snmp = lib.mkIf isMonitoringServer {
      enable = false;
      port = 9116;
      listenAddress = "0.0.0.0";
      openFirewall = false;
    };

    # Open firewall for exporters on Tailscale interface
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      9100 # node_exporter
    ]
    ++ lib.optionals hasZFS [
      9134 # zfs_exporter
    ]
    ++ lib.optionals isMonitoringServer [
      9116 # snmp_exporter
    ];
  };
}

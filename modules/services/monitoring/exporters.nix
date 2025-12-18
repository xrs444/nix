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
    services.prometheus.exporters.snmp = lib.mkIf isMonitoringServer {
      enable = true;
      port = 9116;
      listenAddress = "0.0.0.0";
      openFirewall = false;

      # Basic SNMP exporter config with common modules
      configuration = {
        # Generic network device using standard MIBs
        if_mib = {
          walk = [
            "1.3.6.1.2.1.2" # IF-MIB (interfaces)
            "1.3.6.1.2.1.31" # IF-MIB extended
          ];
          lookups = [
            {
              source_indexes = [ "ifIndex" ];
              lookup = "ifAlias";
            }
            {
              source_indexes = [ "ifIndex" ];
              lookup = "ifDescr";
            }
            {
              source_indexes = [ "ifIndex" ];
              lookup = "ifName";
            }
          ];
          overrides = {
            ifAlias.type = "DisplayString";
            ifDescr.type = "DisplayString";
            ifName.type = "DisplayString";
            ifType.type = "EnumAsInfo";
          };
        };

        # Brocade/Ruckus switches (FastIron, ICX series)
        brocade = {
          walk = [
            "1.3.6.1.2.1.1" # System
            "1.3.6.1.2.1.2" # Interfaces
            "1.3.6.1.2.1.31" # Interface extended
            "1.3.6.1.4.1.1991.1.1.2" # Foundry-specific (CPU, memory, temp)
          ];
        };
      };
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

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

  # Detect if host has libvirt/KVM
  hasLibvirt = builtins.elem hostname [
    "xsvr1"
    "xsvr2"
    "xsvr3"
  ];

  hasBIND = false;
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

    # Libvirt exporter - for VM monitoring on KVM hosts
    # Uses a custom systemd service because the nixpkgs module has a meta.mainProgram
    # mismatch. Binary is named libvirt-exporter (not prometheus-libvirt-exporter) in nixpkgs 25.11.
    systemd.services.prometheus-libvirt-exporter = lib.mkIf hasLibvirt {
      description = "Prometheus Libvirt Exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "libvirtd.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.prometheus-libvirt-exporter}/bin/libvirt-exporter --web.listen-address=0.0.0.0:9177";
        User = "root";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # SMART disk health exporter - all monitoring hosts
    services.prometheus.exporters.smartctl = {
      enable = true;
      port = 9633;
      listenAddress = "0.0.0.0";
      openFirewall = false;
      # Scan for devices automatically
      devices = [ ];
    };

    # BIND DNS exporter - for DNS server monitoring
    services.prometheus.exporters.bind = lib.mkIf hasBIND {
      enable = true;
      port = 9119;
      listenAddress = "0.0.0.0";
      openFirewall = false;
    };

    # Open firewall for exporters on all interfaces.
    # bond0-scoped rules don't work for: (a) ARM hosts (end0/enu1u1u1), (b) k8s
    # pod traffic which arrives on bridge22 not bond0 on the xsvr1-3 KVM hosts.
    networking.firewall.allowedTCPPorts = [
      9080 # alloy (journal->Loki shipper; see promtail.nix)
      9100 # node_exporter
      9633 # smartctl_exporter
    ]
    ++ lib.optionals hasZFS [
      9134 # zfs_exporter
    ]
    ++ lib.optionals hasLibvirt [
      9177 # libvirt_exporter (custom systemd service)
    ]
    ++ lib.optionals hasBIND [
      9119 # bind_exporter
    ];
  };
}

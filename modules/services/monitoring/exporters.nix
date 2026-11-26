# Summary: Prometheus exporters configuration - node_exporter and zfs_exporter.
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  net = import ../../../lib/network.nix;
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

  # Source addresses Prometheus scrapes arrive from: the Talos node subnet (pods are
  # masqueraded to node IPs). The Tailscale range is deliberately NOT allowed: xfw is the
  # tailnet subnet router and some LAN-to-LAN traffic arrives translated to its tailnet
  # address (observed 2026-11-26: the Mac's connection to xpbx1:9100 showed up as
  # 100.126.101.100), so allowing 100.64.0.0/10 let any LAN host through. The cluster has no
  # tailnet route, so nothing legitimate scrapes over it anyway (cmrpi1's ts.net scrape has
  # been down since before this change).
  scrapeCidrs = [
    net.talosNodes
  ];

  exporterPorts = [
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

    # Exporter ports are reachable only from the Prometheus scrape source (N4), not
    # from every network. Prometheus runs in-cluster; its pods are masqueraded to the
    # Talos node IPs in 172.20.3.0/24 (observed live: 172.20.3.20 -> :9100/:9633/:9134/
    # :9177/:9080), so one rule per CIDR+port covers whichever node it lands on.
    # Interface-scoped rules don't work here: ARM hosts use different NIC names and k8s
    # pod traffic arrives on bridge22, not bond0, on the xsvr1-3 KVM hosts.
    # Rules go into nixos-fw (extraCommands runs before the final refuse rule);
    # delete-then-add keeps them idempotent across activations (see keepalived module).
    networking.firewall.extraCommands = lib.concatStringsSep "\n" (
      lib.concatMap (
        cidr:
        map (port: ''
          iptables -D nixos-fw -s ${cidr} -p tcp --dport ${toString port} -j nixos-fw-accept 2>/dev/null || true
          iptables -A nixos-fw -s ${cidr} -p tcp --dport ${toString port} -j nixos-fw-accept
        '') exporterPorts
      ) scrapeCidrs
    );
  };
}

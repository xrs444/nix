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

  # Detect if host runs BIND DNS
  hasBIND = builtins.elem hostname [
    "xlabmgmt"
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
    services.prometheus.exporters.libvirt = lib.mkIf hasLibvirt {
      enable = true;
      port = 9177;
      listenAddress = "0.0.0.0";
      openFirewall = false;
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

    # Blackbox exporter - for SSL certificate and endpoint monitoring (only on monitoring server)
    services.prometheus.exporters.blackbox = lib.mkIf isMonitoringServer {
      enable = true;
      port = 9115;
      listenAddress = "0.0.0.0";
      openFirewall = false;
      configFile = pkgs.writeText "blackbox.yml" ''
        modules:
          http_2xx:
            prober: http
            timeout: 5s
            http:
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
              follow_redirects: true
              preferred_ip_protocol: "ip4"

          http_2xx_tls:
            prober: http
            timeout: 5s
            http:
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
              follow_redirects: true
              preferred_ip_protocol: "ip4"
              tls_config:
                insecure_skip_verify: false

          tcp_connect:
            prober: tcp
            timeout: 5s

          icmp:
            prober: icmp
            timeout: 5s
      '';
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
      9633 # smartctl_exporter
    ]
    ++ lib.optionals hasZFS [
      9134 # zfs_exporter
    ]
    ++ lib.optionals hasLibvirt [
      9177 # libvirt_exporter
    ]
    ++ lib.optionals hasBIND [
      9119 # bind_exporter
    ]
    ++ lib.optionals isMonitoringServer [
      9116 # snmp_exporter
      9115 # blackbox_exporter
    ];
  };
}

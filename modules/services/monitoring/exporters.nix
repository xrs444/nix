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

  # snmp.yml template — community string is substituted at service start from
  # the sops secret at /run/secrets/snmp-community (key: snmp in netbox-prometheus.yaml).
  snmpYmlTemplate = pkgs.writeText "snmp.yml.template" ''
    auths:
      snmp_community:
        community: @SNMP_COMMUNITY@
        security_level: noAuthNoPriv
        auth_protocol: MD5
        priv_protocol: DES
        version: 2

    modules:
      # Standard interface MIB — works with virtually all SNMP-capable devices.
      # Exposes: link state, 32-bit and 64-bit byte counters, error counters.
      if_mib:
        walk:
          - 1.3.6.1.2.1.2.2       # ifTable
          - 1.3.6.1.2.1.31.1.1    # ifXTable
        get:
          - 1.3.6.1.2.1.1.3.0     # sysUpTime
          - 1.3.6.1.2.1.1.5.0     # sysName
        metrics:
          - name: sysUpTime
            oid: 1.3.6.1.2.1.1.3
            type: gauge
            help: "Time since last re-initialization (hundredths of a second)."

          - name: ifAdminStatus
            oid: 1.3.6.1.2.1.2.2.1.7
            type: gauge
            help: "Desired state of the interface. 1=up 2=down 3=testing"
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifOperStatus
            oid: 1.3.6.1.2.1.2.2.1.8
            type: gauge
            help: "Operational state. 1=up 2=down 3=testing 4=unknown 5=dormant 6=notPresent 7=lowerLayerDown"
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifInOctets
            oid: 1.3.6.1.2.1.2.2.1.10
            type: counter
            help: "Total octets received on the interface (32-bit)."
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifOutOctets
            oid: 1.3.6.1.2.1.2.2.1.16
            type: counter
            help: "Total octets transmitted out of the interface (32-bit)."
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifInErrors
            oid: 1.3.6.1.2.1.2.2.1.14
            type: counter
            help: "Inbound packets containing errors."
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifOutErrors
            oid: 1.3.6.1.2.1.2.2.1.20
            type: counter
            help: "Outbound packets that could not be transmitted due to errors."
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifHCInOctets
            oid: 1.3.6.1.2.1.31.1.1.1.6
            type: counter
            help: "Total octets received on the interface (64-bit)."
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString

          - name: ifHCOutOctets
            oid: 1.3.6.1.2.1.31.1.1.1.10
            type: counter
            help: "Total octets transmitted out of the interface (64-bit)."
            indexes:
              - labelname: ifIndex
                type: gauge
            lookups:
              - labels: [ifIndex]
                labelname: ifDescr
                oid: 1.3.6.1.2.1.2.2.1.2
                type: DisplayString
              - labels: [ifIndex]
                labelname: ifName
                oid: 1.3.6.1.2.1.31.1.1.1.1
                type: DisplayString
  '';

  # Script that substitutes @SNMP_COMMUNITY@ in the template and writes the
  # final snmp.yml to the RuntimeDirectory before the exporter starts.
  # Runs as root (ExecStartPre with '+' prefix) so it can read the sops secret.
  generateSnmpYml = pkgs.writeShellScript "generate-snmp-yml" ''
    community=$(cat /run/secrets/snmp-community)
    ${pkgs.gnused}/bin/sed "s/@SNMP_COMMUNITY@/$community/g" \
      ${snmpYmlTemplate} > /run/prometheus-snmp-exporter/snmp.yml
    chmod 640 /run/prometheus-snmp-exporter/snmp.yml
  '';
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
    # Devices are discovered via NetBox (tag: snmp-monitor).
    # See prometheus.nix for the netbox-snmp-discovery timer that populates
    # /var/lib/prometheus/snmp-sd.json for Prometheus file_sd_configs.
    #
    # The snmp.yml is generated at service start from snmpYmlTemplate (let block above),
    # substituting the SNMP community from /run/secrets/snmp-community (sops key: snmp).
    services.prometheus.exporters.snmp = lib.mkIf isMonitoringServer {
      enable = true;
      port = 9116;
      listenAddress = "0.0.0.0";
      openFirewall = false;
      # Disable config validation at eval time — the file lives at a runtime
      # path (/run/...) that doesn't exist in the Nix sandbox.
      enableConfigCheck = false;
      # Points to a runtime path written by ExecStartPre below.
      configurationPath = "/run/prometheus-snmp-exporter/snmp.yml";
    };

    # Generate snmp.yml at service start by substituting the sops-managed
    # community string into the template.  The '+' prefix on ExecStartPre runs
    # the script as root so it can read /run/secrets/snmp-community.
    systemd.services.prometheus-snmp-exporter = lib.mkIf isMonitoringServer {
      serviceConfig = {
        RuntimeDirectory = "prometheus-snmp-exporter";
        RuntimeDirectoryMode = "0755";
        ExecStartPre = "+${generateSnmpYml}";
      };
    };

    # Open firewall for exporters on bond0 (LAN interface) for server-to-server monitoring
    networking.firewall.interfaces.bond0.allowedTCPPorts = [
      9080 # promtail
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
    ]
    ++ lib.optionals isMonitoringServer [
      9116 # snmp_exporter
      9115 # blackbox_exporter
      9091 # pushgateway
    ];

    # Pushgateway — receives deployment metrics pushed from CI (deploy.yml).
    # Only needed on the monitoring server (xsvr1).
    services.prometheus.pushgateway = lib.mkIf isMonitoringServer {
      enable = true;
    };
  };
}

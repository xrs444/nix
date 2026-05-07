# Summary: Prometheus server configuration with scrape targets for all hosts.
{
  hostname,
  hostRoles ? [ ],
  lib,
  ...
}:
let
  isMonitoringServer = lib.elem "monitoring-server" hostRoles;

  # Define all monitored hosts
  # Use static IPs instead of .lan hostnames to avoid VIP/keepalived routing issues
  allHosts = [
    "172.20.1.10" # xsvr1
    "172.20.1.20" # xsvr2
    "172.20.1.30" # xsvr3
    "xlabmgmt.lan"
    "xts1.lan"
    "xts2.lan"
    "xcomm1.lan"
    "xpbx1.lan"
    "cmrpi1.lan" # cmrpi1 - AdGuard Home / RPi5
  ];

  # Hosts with ZFS
  zfsHosts = [
    "172.20.1.10" # xsvr1
    "172.20.1.20" # xsvr2
  ];

  # Hosts with bird BGP
  birdHosts = [
    "xts1.lan"
    "xts2.lan"
  ];

  # Hosts with libvirt
  libvirtHosts = [
    "172.20.1.10" # xsvr1
    "172.20.1.20" # xsvr2
    "172.20.1.30" # xsvr3
  ];

  # Hosts with BIND DNS
  bindHosts = [
    "xlabmgmt.lan"
  ];

  # Talos VMs (Kubernetes nodes)
  talosVMs = [
    "172.20.3.10"
    "172.20.3.20"
    "172.20.3.30"
  ];

  # Generate scrape targets for node_exporter
  nodeTargets = map (host: "${host}:9100") allHosts;

  # Generate scrape targets for zfs_exporter
  zfsTargets = map (host: "${host}:9134") zfsHosts;

  # Generate scrape targets for bird_exporter
  birdTargets = map (host: "${host}:9324") birdHosts;

  # Generate scrape targets for libvirt_exporter
  libvirtTargets = map (host: "${host}:9177") libvirtHosts;

  # Generate scrape targets for smartctl_exporter (all hosts)
  smartctlTargets = map (host: "${host}:9633") allHosts;

  # Generate scrape targets for bind_exporter
  bindTargets = map (host: "${host}:9119") bindHosts;

  # Generate scrape targets for Talos node_exporter (port 9100)
  talosNodeTargets = map (ip: "${ip}:9100") talosVMs;

  # Generate scrape targets for Talos kubelet metrics (port 10250)
  talosKubeletTargets = map (ip: "${ip}:10250") talosVMs;

  # Kubernetes monitoring targets
  k8sTargets = {
    # kube-state-metrics service in monitoring namespace (exposed via NodePort 30080)
    kubeStateMetrics = "172.20.3.10:30080";
    # Kubernetes API server (via first Talos node)
    apiServer = "172.20.3.10:6443";
  };
in
{
  config = lib.mkIf isMonitoringServer {
    services.prometheus = {
      enable = true;
      port = 9090;
      listenAddress = "0.0.0.0";

      # Disable config validation during build (token file not available in sandbox)
      checkConfig = false;

      # Enable reload on config change instead of restart
      enableReload = true;

      # Retention settings
      retentionTime = "30d";

      # Ensure clean restarts
      extraFlags = [
        "--web.enable-lifecycle"
      ];

      # Global scrape configuration
      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };

      # Scrape configurations
      scrapeConfigs = [
        # Scrape Prometheus itself
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "localhost:9090" ];
              labels = {
                instance = hostname;
              };
            }
          ];
        }

        # Node exporter - all hosts
        {
          job_name = "node";
          honor_labels = true;
          static_configs = [
            {
              targets = nodeTargets;
            }
          ];
        }

        # ZFS exporter - hosts with ZFS
        {
          job_name = "zfs";
          static_configs = [
            {
              targets = zfsTargets;
            }
          ];
        }

        # Bird BGP exporter - Tailscale exit nodes
        {
          job_name = "bird";
          static_configs = [
            {
              targets = birdTargets;
            }
          ];
        }

        # SNMP - Network devices (DISABLED - exporter needs reconfiguration)
        # TODO: Re-enable after fixing SNMP exporter config format
        # See exporters.nix for details
        # Brocade switches
        # {
        #   job_name = "snmp-brocade";
        #   scrape_interval = "60s";
        #   static_configs = [
        #     {
        #       targets = [
        #         # "192.168.1.10" # brocade-7250-1 - Replace with your IPs
        #         # "192.168.1.11" # brocade-7250-2
        #         # "192.168.1.12" # brocade-6610
        #       ];
        #     }
        #   ];
        #   metrics_path = "/snmp";
        #   params = {
        #     module = [ "brocade" ];
        #     # auth = [ "public_v2" ]; # Reference to snmp.yml auth config
        #   };
        #   relabel_configs = [
        #     {
        #       source_labels = [ "__address__" ];
        #       target_label = "__param_target";
        #     }
        #     {
        #       source_labels = [ "__param_target" ];
        #       target_label = "instance";
        #     }
        #     {
        #       target_label = "__address__";
        #       replacement = "localhost:9116";
        #     }
        #   ];
        # }

        # Generic network devices (Firewalla, Omada, etc.)
        # {
        #   job_name = "snmp-network";
        #   scrape_interval = "60s";
        #   static_configs = [
        #     {
        #       targets = [
        #         # "192.168.1.1" # firewalla-pro - Replace with your IPs
        #         # "192.168.1.20" # omada-controller
        #         # "192.168.1.21" # omada-ap-1
        #       ];
        #     }
        #   ];
        #   metrics_path = "/snmp";
        #   params = {
        #     module = [ "if_mib" ];
        #   };
        #   relabel_configs = [
        #     {
        #       source_labels = [ "__address__" ];
        #       target_label = "__param_target";
        #     }
        #     {
        #       source_labels = [ "__param_target" ];
        #       target_label = "instance";
        #     }
        #     {
        #       target_label = "__address__";
        #       replacement = "localhost:9116";
        #     }
        #   ];
        # }

        # Talos VMs - node_exporter
        # System-level metrics from Talos Kubernetes nodes
        {
          job_name = "talos-node";
          static_configs = [
            {
              targets = talosNodeTargets;
              labels = {
                cluster = "home-k8s";
                role = "talos-vm";
              };
            }
          ];
        }

        # Talos VMs - kubelet metrics
        # Container and pod metrics from kubelet
        {
          job_name = "kubelet";
          scheme = "https";
          tls_config = {
            insecure_skip_verify = true;
          };
          authorization = {
            type = "Bearer";
            credentials_file = "/var/lib/prometheus/k8s-token";
          };
          static_configs = [
            {
              targets = talosKubeletTargets;
              labels = {
                cluster = "home-k8s";
              };
            }
          ];
        }

        # Kubernetes API Server
        # Control plane metrics
        {
          job_name = "kubernetes-apiserver";
          scheme = "https";
          tls_config = {
            insecure_skip_verify = true;
          };
          authorization = {
            type = "Bearer";
            credentials_file = "/var/lib/prometheus/k8s-token";
          };
          static_configs = [
            {
              targets = [ k8sTargets.apiServer ];
              labels = {
                cluster = "home-k8s";
              };
            }
          ];
        }

        # Kubernetes - kube-state-metrics
        # Provides cluster-level metrics about Kubernetes objects
        {
          job_name = "kube-state-metrics";
          scrape_interval = "30s";
          static_configs = [
            {
              targets = [ k8sTargets.kubeStateMetrics ];
              labels = {
                cluster = "home-k8s";
              };
            }
          ];
        }

        # Libvirt exporter - VM monitoring on KVM hosts (xsvr1, xsvr2, xsvr3)
        {
          job_name = "libvirt";
          static_configs = [
            {
              targets = libvirtTargets;
            }
          ];
        }

        # SMART disk health monitoring
        {
          job_name = "smartctl";
          scrape_interval = "60s";
          scrape_timeout = "30s";
          static_configs = [
            {
              targets = smartctlTargets;
            }
          ];
        }

        # BIND DNS exporter
        {
          job_name = "bind";
          static_configs = [
            {
              targets = bindTargets;
            }
          ];
        }

        # Blackbox exporter - SSL certificate and endpoint monitoring
        {
          job_name = "blackbox-ssl";
          metrics_path = "/probe";
          params = {
            module = [ "http_2xx_tls" ];
          };
          static_configs = [
            {
              targets = [
                "https://loki.xrs444.net"
                "https://kanidm.xrs444.net"
                "https://grafana.xrs444.net"
                "https://immich.xrs444.net"
                "https://netbox.xrs444.net"
                "https://paperless.xrs444.net"
                "https://ntfy.xrs444.net"
                "https://jellyfin.xrs444.net"
                "https://mealie.xrs444.net"
                "https://audiobookshelf.xrs444.net"
                "https://sonarr.xrs444.net"
                "https://radarr.xrs444.net"
                "https://lidarr.xrs444.net"
                "https://garage.xrs444.net"
              ];
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "localhost:9115";
            }
          ];
        }

        # Promtail metrics - log shipper health monitoring
        {
          job_name = "promtail";
          static_configs = [
            {
              targets = map (host: "${host}:9080") allHosts;
            }
          ];
        }

        # Home Assistant metrics
        {
          job_name = "homeassistant";
          scrape_interval = "60s";
          scrape_timeout = "10s";
          metrics_path = "/api/prometheus";

          # Bearer token authentication
          authorization = {
            type = "Bearer";
            credentials_file = "/var/lib/prometheus/homeassistant-token";
          };

          static_configs = [
            {
              # Replace with your Home Assistant hostname/IP
              targets = [ "hass.xrs444.net:8123" ];
              labels = {
                instance = "home";
                environment = "production";
                service = "homeassistant";
              };
            }
          ];

          # Optional: Filter metrics to reduce cardinality
          # Uncomment and adjust as needed
          # metric_relabel_configs = [
          #   # Keep only specific metric types
          #   {
          #     source_labels = [ "__name__" ];
          #     regex = "homeassistant_(sensor|binary_sensor|light|switch|climate|cover)_.*";
          #     action = "keep";
          #   }
          # ];
        }

        # Asterisk PBX metrics via res_prometheus (HTTP on port 8088)
        {
          job_name = "asterisk";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "xpbx1.lan:8088" ];
              labels = {
                instance = "xpbx1";
              };
            }
          ];
        }

        # Kubernetes - Traefik ingress controller metrics (via NodePort)
        {
          job_name = "traefik";
          static_configs = [
            {
              targets = [ "172.20.3.10:30090" ]; # NodePort to be created
              labels = {
                cluster = "home-k8s";
                component = "traefik";
              };
            }
          ];
        }

        # Kubernetes - Cilium CNI metrics (via NodePort)
        {
          job_name = "cilium";
          static_configs = [
            {
              targets = [ "172.20.3.10:30091" ]; # NodePort to be created
              labels = {
                cluster = "home-k8s";
                component = "cilium";
              };
            }
          ];
        }

        # Kubernetes - Cert-Manager metrics (via NodePort)
        {
          job_name = "cert-manager";
          static_configs = [
            {
              targets = [ "172.20.3.10:30092" ]; # NodePort to be created
              labels = {
                cluster = "home-k8s";
                component = "cert-manager";
              };
            }
          ];
        }

        # Pushgateway — receives deployment metrics pushed from CI (deploy.yml).
        # honor_labels preserves the instance/job labels set by the pushing client.
        {
          job_name = "pushgateway";
          honor_labels = true;
          static_configs = [
            {
              targets = [ "localhost:9091" ];
            }
          ];
        }

        # Kubernetes - Garage S3 storage metrics (admin API, via NodePort)
        {
          job_name = "garage";
          static_configs = [
            {
              targets = [ "172.20.3.10:30100" ];
              labels = {
                cluster = "home-k8s";
                component = "garage";
              };
            }
          ];
        }

        # Kubernetes - Loki log aggregation metrics (via NodePort)
        {
          job_name = "loki";
          static_configs = [
            {
              targets = [ "172.20.3.10:30101" ];
              labels = {
                cluster = "home-k8s";
                component = "loki";
              };
            }
          ];
        }

        # Kubernetes - Longhorn distributed storage metrics (via NodePort)
        {
          job_name = "longhorn";
          scrape_interval = "30s";
          static_configs = [
            {
              targets = [ "172.20.3.10:30102" ];
              labels = {
                cluster = "home-k8s";
                component = "longhorn";
              };
            }
          ];
        }

        # Kubernetes - ntfy push notification metrics (via NodePort)
        {
          job_name = "ntfy";
          metrics_path = "/v1/metrics";
          static_configs = [
            {
              targets = [ "172.20.3.10:30103" ];
              labels = {
                cluster = "home-k8s";
                component = "ntfy";
              };
            }
          ];
        }

        # Kubernetes - Spegel container image cache metrics (via NodePort)
        {
          job_name = "spegel";
          static_configs = [
            {
              targets = [ "172.20.3.10:30105" ];
              labels = {
                cluster = "home-k8s";
                component = "spegel";
              };
            }
          ];
        }

        # Kubernetes - Immich photo server metrics (via NodePort)
        {
          job_name = "immich";
          static_configs = [
            {
              targets = [ "172.20.3.10:30106" ];
              labels = {
                cluster = "home-k8s";
                component = "immich";
              };
            }
          ];
        }

        # Kubernetes - NetBox network source of truth metrics (via NodePort)
        {
          job_name = "netbox";
          static_configs = [
            {
              targets = [ "172.20.3.10:30107" ];
              labels = {
                cluster = "home-k8s";
                component = "netbox";
              };
            }
          ];
        }

        # Kubernetes - Sonarr TV manager metrics (Exportarr sidecar, via NodePort)
        {
          job_name = "sonarr";
          static_configs = [
            {
              targets = [ "172.20.3.10:30110" ];
              labels = {
                cluster = "home-k8s";
                component = "sonarr";
              };
            }
          ];
        }

        # Kubernetes - Radarr movie manager metrics (Exportarr sidecar, via NodePort)
        {
          job_name = "radarr";
          static_configs = [
            {
              targets = [ "172.20.3.10:30111" ];
              labels = {
                cluster = "home-k8s";
                component = "radarr";
              };
            }
          ];
        }

        # Kubernetes - Lidarr music manager metrics (Exportarr sidecar, via NodePort)
        {
          job_name = "lidarr";
          static_configs = [
            {
              targets = [ "172.20.3.10:30112" ];
              labels = {
                cluster = "home-k8s";
                component = "lidarr";
              };
            }
          ];
        }
      ];

      # Alert rules
      rules = [
        (builtins.toJSON {
          groups = [
            {
              name = "node_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "InstanceDown";
                  expr = "up == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Instance {{ $labels.instance }} down";
                    description = "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes.";
                  };
                }
                {
                  alert = "HighCPUUsage";
                  expr = ''(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80'';
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "High CPU usage on {{ $labels.instance }}";
                    description = "CPU usage is above 80% (current value: {{ $value }}%)";
                  };
                }
                {
                  alert = "HighMemoryUsage";
                  expr = ''(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90'';
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "High memory usage on {{ $labels.instance }}";
                    description = "Memory usage is above 90% (current value: {{ $value }}%)";
                  };
                }
                {
                  alert = "DiskSpaceLow";
                  expr = ''(node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs|squashfs|vfat"} / node_filesystem_size_bytes) * 100 < 10'';
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Disk space low on {{ $labels.instance }}";
                    description = "Filesystem {{ $labels.mountpoint }} has less than 10% space remaining (current: {{ $value }}%)";
                  };
                }
              ];
            }
            {
              name = "kubernetes_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "KubernetesPodCrashLooping";
                  expr = "rate(kube_pod_container_status_restarts_total[15m]) > 0";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping";
                    description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has restarted {{ $value }} times in the last 15 minutes.";
                  };
                }
                {
                  alert = "KubernetesPodNotReady";
                  expr = "kube_pod_status_phase{phase!~\"Running|Succeeded\"} > 0";
                  for = "15m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Pod {{ $labels.namespace }}/{{ $labels.pod }} not ready";
                    description = "Pod has been in a non-ready state for more than 15 minutes.";
                  };
                }
                {
                  alert = "KubernetesNodeNotReady";
                  expr = "kube_node_status_condition{condition=\"Ready\",status=\"true\"} == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Kubernetes node {{ $labels.node }} not ready";
                    description = "Node has been in a not-ready state for more than 5 minutes.";
                  };
                }
              ];
            }
            {
              name = "zfs_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "ZFSPoolDegraded";
                  expr = "zfs_pool_health != 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "ZFS pool degraded on {{ $labels.instance }}";
                    description = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} is not in ONLINE state.";
                  };
                }
                {
                  alert = "ZFSPoolLowSpace";
                  expr = "(zfs_pool_free_bytes / zfs_pool_size_bytes) * 100 < 10";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "ZFS pool low on space on {{ $labels.instance }}";
                    description = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} has less than 10% free space (current: {{ $value }}%)";
                  };
                }
                {
                  alert = "ZFSScrubErrors";
                  expr = "zfs_pool_scrub_errors > 0";
                  for = "1m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "ZFS scrub found errors on {{ $labels.instance }}";
                    description = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} has {{ $value }} scrub errors.";
                  };
                }
              ];
            }
            {
              name = "smartctl_alerts";
              interval = "60s";
              rules = [
                {
                  alert = "SMARTDeviceFailing";
                  expr = "smartctl_device_smart_healthy == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "SMART indicates device failure on {{ $labels.instance }}";
                    description = "Device {{ $labels.device }} on {{ $labels.instance }} is reporting SMART health failure.";
                  };
                }
                {
                  alert = "SMARTHighTemperature";
                  expr = "smartctl_device_temperature > 60";
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "High disk temperature on {{ $labels.instance }}";
                    description = "Device {{ $labels.device }} temperature is {{ $value }}°C (threshold: 60°C)";
                  };
                }
              ];
            }
            {
              name = "backup_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "BackupJobFailed";
                  expr = "node_systemd_unit_state{name=~\"borgbackup.*\\\\.service\",state=\"failed\"} == 1";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Backup job failed on {{ $labels.instance }}";
                    description = "Systemd unit {{ $labels.name }} on {{ $labels.instance }} is in failed state.";
                  };
                }
                {
                  alert = "BackupJobNotRunRecently";
                  expr = "(time() - node_systemd_unit_state_change_timestamp_seconds{name=~\"borgbackup.*\\\\.service\"}) > 172800";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Backup job has not run recently on {{ $labels.instance }}";
                    description = "Backup unit {{ $labels.name }} has not changed state in over 48 hours.";
                  };
                }
              ];
            }
            {
              name = "ssl_certificate_alerts";
              interval = "60s";
              rules = [
                {
                  alert = "SSLCertificateExpiringSoon";
                  expr = "(probe_ssl_earliest_cert_expiry - time()) / 86400 < 14";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "SSL certificate expiring soon for {{ $labels.instance }}";
                    description = "SSL certificate for {{ $labels.instance }} expires in {{ $value }} days.";
                  };
                }
                {
                  alert = "SSLCertificateExpired";
                  expr = "(probe_ssl_earliest_cert_expiry - time()) < 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "SSL certificate expired for {{ $labels.instance }}";
                    description = "SSL certificate for {{ $labels.instance }} has expired!";
                  };
                }
              ];
            }
            {
              name = "libvirt_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "LibvirtDomainDown";
                  expr = "libvirt_domain_info_state != 1";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Libvirt domain {{ $labels.domain }} is not running on {{ $labels.instance }}";
                    description = "VM {{ $labels.domain }} on {{ $labels.instance }} is in state {{ $value }} (1=running).";
                  };
                }
              ];
            }
            {
              name = "bgp_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "BGPSessionDown";
                  expr = "bird_protocol_up{proto=\"BGP\"} != 1";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "BGP session down on {{ $labels.instance }}";
                    description = "BGP protocol {{ $labels.name }} on {{ $labels.instance }} is not in Established state.";
                  };
                }
                {
                  alert = "BGPPeerFlapping";
                  expr = "rate(bird_protocol_up{proto=\"BGP\"}[15m]) > 0.1";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "BGP peer flapping on {{ $labels.instance }}";
                    description = "BGP protocol {{ $labels.name }} is flapping on {{ $labels.instance }}.";
                  };
                }
                {
                  alert = "TailscaleExitNodeBothDown";
                  expr = "count(up{job=\"bird\"} == 0) == 2";
                  for = "3m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Both Tailscale exit nodes are down";
                    description = "Both xts1 and xts2 are unreachable. Tailscale exit node service is unavailable.";
                  };
                }
                {
                  alert = "BirdExporterDown";
                  expr = "up{job=\"bird\"} == 0";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Bird exporter down on {{ $labels.instance }}";
                    description = "Bird exporter on {{ $labels.instance }} has been down for more than 5 minutes.";
                  };
                }
              ];
            }
            {
              name = "longhorn_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "LonghornVolumeDegraded";
                  expr = "longhorn_volume_robustness > 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Longhorn volume {{ $labels.volume }} is degraded";
                    description = "Longhorn volume {{ $labels.volume }} has robustness state {{ $value }} (0=healthy, 1=degraded, 2=faulted).";
                  };
                }
                {
                  alert = "LonghornDiskFull";
                  expr = "(longhorn_disk_usage_bytes / longhorn_disk_capacity_bytes) * 100 > 90";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Longhorn disk nearly full on {{ $labels.node }}";
                    description = "Longhorn disk {{ $labels.disk }} on {{ $labels.node }} is {{ $value }}% full (threshold: 90%).";
                  };
                }
                {
                  alert = "LonghornBackupFailed";
                  expr = "longhorn_backup_state == 4";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Longhorn backup failed for volume {{ $labels.volume }}";
                    description = "Backup {{ $labels.backup }} for volume {{ $labels.volume }} is in Error state.";
                  };
                }
              ];
            }
            {
              name = "garage_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "GarageDown";
                  expr = "up{job=\"garage\"} == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Garage S3 storage is down";
                    description = "Garage exporter has been unreachable for more than 5 minutes.";
                  };
                }
                {
                  alert = "GarageNodeDown";
                  expr = "garage_cluster_nodes_up < 3";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Garage cluster node down ({{ $value }}/3 nodes up)";
                    description = "One or more Garage cluster nodes are not responding.";
                  };
                }
              ];
            }
            {
              name = "loki_alerts";
              interval = "30s";
              rules = [
                {
                  alert = "LokiDown";
                  expr = "up{job=\"loki\"} == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Loki log aggregation is down";
                    description = "Loki exporter has been unreachable for more than 5 minutes. Log ingestion may be failing.";
                  };
                }
                {
                  alert = "LokiHighIngestionLatency";
                  expr = ''histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket{route=~"loki_api_v1_push"}[5m])) by (le)) > 5'';
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Loki ingestion p99 latency is high";
                    description = "Loki push API p99 latency is {{ $value }}s (threshold: 5s).";
                  };
                }
                {
                  alert = "LokiHighErrorRate";
                  expr = ''sum(rate(loki_request_duration_seconds_count{status_code=~"5.."}[5m])) / sum(rate(loki_request_duration_seconds_count[5m])) > 0.05'';
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Loki error rate is high";
                    description = "More than 5% of Loki requests are returning 5xx errors.";
                  };
                }
              ];
            }
            {
              name = "certmanager_alerts";
              interval = "60s";
              rules = [
                {
                  alert = "CertificateNotReady";
                  expr = "certmanager_certificate_ready_status{condition=\"False\"} == 1";
                  for = "15m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Certificate {{ $labels.name }} in {{ $labels.namespace }} is not ready";
                    description = "cert-manager certificate {{ $labels.namespace }}/{{ $labels.name }} has not become ready after 15 minutes.";
                  };
                }
                {
                  alert = "CertificateExpiringSoon";
                  expr = "(certmanager_certificate_expiration_timestamp_seconds - time()) / 86400 < 14";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Certificate {{ $labels.name }} expires in {{ $value }} days";
                    description = "cert-manager certificate {{ $labels.namespace }}/{{ $labels.name }} expires in {{ $value }} days.";
                  };
                }
                {
                  alert = "CertificateExpired";
                  expr = "(certmanager_certificate_expiration_timestamp_seconds - time()) < 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Certificate {{ $labels.name }} has expired";
                    description = "cert-manager certificate {{ $labels.namespace }}/{{ $labels.name }} has expired.";
                  };
                }
                {
                  alert = "CertManagerACMEErrors";
                  expr = "sum(rate(certmanager_http_acme_client_request_count{status=~\"4..|5..\"}[1h])) > 0.1";
                  for = "30m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "cert-manager ACME client errors detected";
                    description = "cert-manager is experiencing ACME request errors at {{ $value }} req/s.";
                  };
                }
              ];
            }
            {
              name = "arr_alerts";
              interval = "60s";
              rules = [
                {
                  alert = "SonarrQueueStuck";
                  expr = "sonarr_queue_total > 10";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Sonarr download queue has {{ $value }} stuck items";
                    description = "Sonarr has had more than 10 items in the queue for over 1 hour. Possible download client issue.";
                  };
                }
                {
                  alert = "RadarrQueueStuck";
                  expr = "radarr_queue_total > 10";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Radarr download queue has {{ $value }} stuck items";
                    description = "Radarr has had more than 10 items in the queue for over 1 hour. Possible download client issue.";
                  };
                }
                {
                  alert = "LidarrQueueStuck";
                  expr = "lidarr_queue_total > 10";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Lidarr download queue has {{ $value }} stuck items";
                    description = "Lidarr has had more than 10 items in the queue for over 1 hour. Possible download client issue.";
                  };
                }
                {
                  alert = "SonarrDown";
                  expr = "up{job=\"sonarr\"} == 0";
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Sonarr is down";
                    description = "Sonarr exporter has been unreachable for more than 10 minutes.";
                  };
                }
                {
                  alert = "RadarrDown";
                  expr = "up{job=\"radarr\"} == 0";
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Radarr is down";
                    description = "Radarr exporter has been unreachable for more than 10 minutes.";
                  };
                }
              ];
            }
          ];
        })
      ];

      # Alertmanager configuration
      alertmanagers = [
        {
          static_configs = [
            {
              targets = [ "localhost:9093" ];
            }
          ];
        }
      ];
    };

    # Enable and configure Alertmanager
    services.prometheus.alertmanager = {
      enable = true;
      port = 9093;
      listenAddress = "0.0.0.0";
      webExternalUrl = "http://xsvr1:9093";

      configuration = {
        global = {
          resolve_timeout = "5m";
        };

        route = {
          group_by = [
            "alertname"
            "cluster"
            "service"
          ];
          group_wait = "10s";
          group_interval = "10s";
          repeat_interval = "12h";
          receiver = "default";

          # Route critical alerts differently
          routes = [
            {
              match = {
                severity = "critical";
              };
              receiver = "critical";
              repeat_interval = "4h";
            }
          ];
        };

        receivers = [
          {
            name = "default";
            webhook_configs = [
              {
                url = "http://apprise.apprise.svc.cluster.local:8000/notify?tag=critical-infra";
                send_resolved = true;
              }
            ];
          }
          {
            name = "critical";
            webhook_configs = [
              {
                url = "http://apprise.apprise.svc.cluster.local:8000/notify?tag=critical-infra";
                send_resolved = true;
              }
            ];
          }
        ];

        # Inhibit rules - suppress warnings when critical alert is firing
        inhibit_rules = [
          {
            source_match = {
              severity = "critical";
            };
            target_match = {
              severity = "warning";
            };
            equal = [
              "alertname"
              "instance"
            ];
          }
        ];
      };
    };

    # Ensure Prometheus service has proper restart behavior
    systemd.services.prometheus = {
      serviceConfig = {
        # Allow time for graceful shutdown
        TimeoutStopSec = "30s";
        # Kill any lingering processes
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        # Ensure port is freed on stop
        RestartSec = "5s";
      };
    };

    # Ensure Alertmanager service has proper restart behavior
    systemd.services.alertmanager = {
      serviceConfig = {
        TimeoutStopSec = "30s";
        KillMode = "mixed";
        RestartSec = "5s";
      };
    };
  };
}

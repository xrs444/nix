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
  allHosts = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
    "xlabmgmt"
    "xts1"
    "xts2"
    "xcomm1"
    "xdash1"
    "xhac-radio"
  ];

  # Hosts with ZFS
  zfsHosts = [
    "xsvr1"
    "xsvr2"
  ];

  # Hosts with bird BGP
  birdHosts = [
    "xts1"
    "xts2"
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

  # Generate scrape targets for Talos node_exporter (port 9100)
  talosNodeTargets = map (ip: "${ip}:9100") talosVMs;

  # Generate scrape targets for Talos kubelet metrics (port 10250)
  talosKubeletTargets = map (ip: "${ip}:10250") talosVMs;

  # Kubernetes monitoring targets
  k8sTargets = {
    # kube-state-metrics service in monitoring namespace (exposed via NodePort 30080)
    kubeStateMetrics = "172.20.3.10:30080";
    # n8n workflow automation service
    n8n = "n8n.n8n.svc.cluster.local:5678";
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

        # n8n workflow automation
        {
          job_name = "n8n";
          scrape_interval = "30s";
          static_configs = [
            {
              targets = [ k8sTargets.n8n ];
              labels = {
                cluster = "home-k8s";
                app = "n8n";
              };
            }
          ];
        }

        # TODO: Add more Kubernetes monitoring:
        # - kubelet metrics (node-level container metrics)
        # - cAdvisor metrics (container resource usage)
        # - API server metrics
        # - etcd metrics (if running separate from API server)
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
                url = "http://apprise.monitoring.svc.cluster.local:8000/notify";
                send_resolved = true;
              }
            ];
          }
          {
            name = "critical";
            webhook_configs = [
              {
                url = "http://apprise.monitoring.svc.cluster.local:8000/notify";
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

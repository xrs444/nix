# Summary: Prometheus server configuration with scrape targets for all hosts.
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
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

  # Generate scrape targets for node_exporter
  nodeTargets = map (host: "${host}:9100") allHosts;

  # Generate scrape targets for zfs_exporter
  zfsTargets = map (host: "${host}:9134") zfsHosts;

  # Kubernetes monitoring targets
  # TODO: Replace with your actual K8s service IPs or use DNS names
  k8sTargets = {
    # kube-state-metrics service in monitoring namespace
    kubeStateMetrics = "kube-state-metrics.monitoring.svc.cluster.local:8080";
    # Add more K8s targets here as needed
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

        # SNMP - Network devices
        # Brocade switches
        {
          job_name = "snmp-brocade";
          scrape_interval = "60s";
          static_configs = [
            {
              targets = [
                # "192.168.1.10" # brocade-7250-1 - Replace with your IPs
                # "192.168.1.11" # brocade-7250-2
                # "192.168.1.12" # brocade-6610
              ];
            }
          ];
          metrics_path = "/snmp";
          params = {
            module = [ "brocade" ];
            # auth = [ "public_v2" ]; # Reference to snmp.yml auth config
          };
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
              replacement = "localhost:9116";
            }
          ];
        }

        # Generic network devices (Firewalla, Omada, etc.)
        {
          job_name = "snmp-network";
          scrape_interval = "60s";
          static_configs = [
            {
              targets = [
                # "192.168.1.1" # firewalla-pro - Replace with your IPs
                # "192.168.1.20" # omada-controller
                # "192.168.1.21" # omada-ap-1
              ];
            }
          ];
          metrics_path = "/snmp";
          params = {
            module = [ "if_mib" ];
          };
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
              replacement = "localhost:9116";
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

        # TODO: Add more Kubernetes monitoring:
        # - kubelet metrics (node-level container metrics)
        # - cAdvisor metrics (container resource usage)
        # - API server metrics
        # - etcd metrics (if running separate from API server)
      ];

      # TODO: Add alerting rules and alertmanager config
      # rules = [];
    };
  };
}

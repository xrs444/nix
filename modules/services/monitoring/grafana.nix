# Summary: Grafana configuration with Prometheus datasource provisioning.
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  isMonitoringServer = lib.elem "monitoring-server" hostRoles;
in
{
  config = lib.mkIf isMonitoringServer {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = "${hostname}";
          # TODO: Configure root_url if using reverse proxy
        };

        # Security settings
        security = {
          admin_user = "admin";
          # TODO: Use secrets management for password
          # admin_password should be set via environment file
        };

        # Anonymous access disabled by default
        "auth.anonymous" = {
          enabled = false;
        };
      };

      # Provision Prometheus datasource
      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:9090";
            isDefault = true;
            jsonData = {
              timeInterval = "15s";
            };
          }
        ];

        # Dashboard provisioning
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "default";
              orgId = 1;
              folder = "";
              type = "file";
              disableDeletion = false;
              updateIntervalSeconds = 30;
              allowUpdating = true;
              options = {
                path = "/var/lib/grafana/dashboards";
              };
            }
          ];
        };
      };
    };

    # Ensure Grafana starts after Prometheus
    systemd.services.grafana.after = [ "prometheus.service" ];

    # Create dashboards directory and populate with pre-configured dashboards
    systemd.services.grafana-setup-dashboards = {
      description = "Setup Grafana Dashboards";
      wantedBy = [ "grafana.service" ];
      before = [ "grafana.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /var/lib/grafana/dashboards

        # Create a README to document dashboard sources
        cat > /var/lib/grafana/dashboards/README.md <<'EOF'
        # Grafana Dashboards

        This directory contains provisioned Grafana dashboards for monitoring the HomeProd infrastructure.

        ## Available Dashboards

        To add dashboards:
        1. Download dashboard JSON from https://grafana.com/grafana/dashboards/
        2. Place JSON files in nix/modules/services/monitoring/dashboards/
        3. Run nixos-rebuild to deploy

        ## Recommended Dashboards

        - Node Exporter Full: https://grafana.com/grafana/dashboards/1860
        - Kubernetes Cluster Monitoring: https://grafana.com/grafana/dashboards/315
        - ZFS: https://grafana.com/grafana/dashboards/7845
        - BGP/Bird: Custom dashboard needed

        EOF

        # Copy any dashboard JSON files from the nix store
        ${lib.concatMapStringsSep "\n" (file:
          "cp ${file} /var/lib/grafana/dashboards/"
        ) (lib.filesystem.listFilesRecursive ./dashboards)}

        chown -R grafana:grafana /var/lib/grafana/dashboards
      '';
    };
  };
}

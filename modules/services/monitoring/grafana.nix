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

        # TODO: Add dashboard provisioning
        # dashboards.settings = {};
      };
    };

    # Ensure Grafana starts after Prometheus
    systemd.services.grafana.after = [ "prometheus.service" ];
  };
}

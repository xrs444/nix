# Summary: Promtail configuration for shipping systemd journal logs to Loki
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  config,
  ...
}:
let
  isMonitoringServer = lib.elem "monitoring-server" hostRoles;
  isMonitoringClient = lib.elem "monitoring-client" hostRoles;
  enablePromtail = isMonitoringServer || isMonitoringClient;

  lokiFallbackUrl = "https://loki.xrs444.net/loki/api/v1/push";
in
{
  config = lib.mkIf enablePromtail {
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };

        clients = [
          {
            url = lokiFallbackUrl;
          }
        ];

        scrape_configs = [
          # Systemd journal scraping
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = hostname;
              };
            };
            relabel_configs = [
              # Extract systemd unit name
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              # Extract systemd slice
              {
                source_labels = [ "__journal__systemd_slice" ];
                target_label = "slice";
              }
              # Extract transport (stdout, stderr, syslog, etc.)
              {
                source_labels = [ "__journal__transport" ];
                target_label = "transport";
              }
              # Extract priority/severity
              {
                source_labels = [ "__journal_priority" ];
                target_label = "priority";
              }
              # Extract syslog identifier
              {
                source_labels = [ "__journal_syslog_identifier" ];
                target_label = "syslog_identifier";
              }
            ];
          }

          # Additional scrape for important log files not in journal
          {
            job_name = "system-logs";
            static_configs = [
              {
                targets = [ "localhost" ];
                labels = {
                  job = "system-logs";
                  host = hostname;
                  __path__ = "/var/log/*.log";
                };
              }
            ];
          }
        ];
      };
    };

    # Ensure promtail has permissions to read journal and state dir exists
    systemd.services.promtail.serviceConfig = {
      SupplementaryGroups = [ "systemd-journal" ];
      StateDirectory = "promtail";
    };

    # Open firewall for promtail metrics endpoint on Tailscale
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      9080 # promtail metrics
    ];
  };
}

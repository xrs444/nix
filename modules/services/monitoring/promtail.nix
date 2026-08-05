# Log forwarding to Loki via Grafana Alloy (replaces promtail, removed in 26.05)
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
  enableAlloy = isMonitoringServer || isMonitoringClient;

  lokiUrl = "https://loki.xrs444.net/loki/api/v1/push";

  alloyConfig = pkgs.writeText "alloy-config.alloy" ''
    loki.source.journal "journal" {
      forward_to = [loki.relabel.journal.receiver]
      max_age    = "12h"
      labels     = {
        host = "${hostname}",
        job  = "systemd-journal",
      }
    }

    loki.relabel "journal" {
      forward_to = [loki.write.default.receiver]
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal__systemd_slice"]
        target_label  = "slice"
      }
      rule {
        source_labels = ["__journal__transport"]
        target_label  = "transport"
      }
      rule {
        source_labels = ["__journal_priority"]
        target_label  = "priority"
      }
      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
      }
    }

    loki.write "default" {
      endpoint {
        url = "${lokiUrl}"
      }
    }
  '';
in
{
  config = lib.mkIf enableAlloy {
    services.alloy = {
      enable = true;
      configPath = alloyConfig;
      # Alloy's default HTTP server only binds 127.0.0.1:12345 — the "keep port 9080"
      # firewall rule below was a stale assumption carried over from the old promtail
      # migration and scraped nothing fleet-wide. Bind explicitly so /metrics is
      # actually reachable on the port everyone assumes it's on.
      extraFlags = [ "--server.http.listen-addr=0.0.0.0:9080" ];
    };

    # Add journal access via service config (services.alloy creates the user/group)
    systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];

    # Keep port 9080 for Prometheus scraping (matches old promtail scrape target)
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      9080 # alloy HTTP metrics
    ];
  };
}

# Summary: Prometheus server configuration with scrape targets for all hosts.
{
  hostname,
  hostRoles ? [ ],
  config,
  lib,
  pkgs,
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
    "172.18.10.1" # xts1 — static IP avoids VIP/keepalived routing issues
    "172.18.10.2" # xts2 — static IP avoids VIP/keepalived routing issues
    "xcomm1.lan"
    "xpbx1.lan"
    # cmrpi1 removed — host decommissioned, DNS NXDOMAIN
  ];

  # Hosts with ZFS
  zfsHosts = [
    "172.20.1.10" # xsvr1
    "172.20.1.20" # xsvr2
  ];

  # Hosts with bird BGP — Tailscale exit nodes
  birdExitHosts = [
    "172.18.10.1" # xts1
    "172.18.10.2" # xts2
  ];

  # Hosts with bird BGP — K8s gateway nodes (xsvr)
  birdGatewayHosts = [
    "172.20.1.10" # xsvr1
    "172.20.1.20" # xsvr2
    "172.20.1.30" # xsvr3
  ];

  # Hosts with libvirt
  libvirtHosts = [
    "172.20.1.10" # xsvr1
    "172.20.1.20" # xsvr2
    "172.20.1.30" # xsvr3
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
  birdExitTargets = map (host: "${host}:9324") birdExitHosts;
  birdGatewayTargets = map (host: "${host}:9324") birdGatewayHosts;

  # Generate scrape targets for libvirt_exporter
  libvirtTargets = map (host: "${host}:9177") libvirtHosts;

  # Generate scrape targets for smartctl_exporter (all hosts)
  smartctlTargets = map (host: "${host}:9633") allHosts;

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

  # NetBox SNMP service discovery script.
  # Queries NetBox for devices tagged 'snmp-monitor', writes Prometheus file_sd JSON.
  #
  # NetBox setup required (one-time, via the NetBox UI or API):
  #   1. Create tag:          Administration → Tags → "snmp-monitor"
  #   2. Create custom field: Customization → Custom Fields
  #        - Object type: dcim | device
  #        - Name: snmp_module   Type: Text   Default: if_mib
  #          (options: if_mib — add more modules to snmp.yml in exporters.nix as needed)
  #   3. Tag devices and set snmp_module custom field as appropriate.
  #   4. Create a read-only API token: Profile → API Tokens
  #   5. Encrypt the token: see the sops.secrets."netbox-token" block above.
  netboxSnmpDiscovery = pkgs.writeScript "netbox-snmp-discovery" ''
    #!${pkgs.python3}/bin/python3
    """
    Queries NetBox for devices tagged 'snmp-monitor' and writes a Prometheus
    file_sd JSON file to /var/lib/prometheus/snmp-sd.json.

    Each device entry carries:
      __param_module  — SNMP module (from custom field snmp_module, default: if_mib)
      device_name     — NetBox device name (used as the 'instance' label)
      device_role     — NetBox device role name
      site            — NetBox site name
    """
    import json
    import os
    import sys
    import urllib.request
    import urllib.error

    NETBOX_URL      = "https://netbox.xrs444.net"
    TOKEN_FILE      = "${config.sops.secrets."netbox-token".path}"
    COMMUNITY_FILE  = "${config.sops.secrets."snmp-community".path}"
    OUTPUT_FILE     = "/var/lib/prometheus/snmp-sd.json"
    TAG_FILTER      = "snmp-monitor"
    DEFAULT_MODULE  = "if_mib"

    def read_file(path, label):
        try:
            with open(path) as f:
                return f.read().strip()
        except Exception as e:
            print(f"ERROR reading {label} from {path}: {e}", flush=True)
            sys.exit(1)

    def fetch_devices(token):
        url = f"{NETBOX_URL}/api/dcim/devices/?tag={TAG_FILTER}&status=active&limit=1000"
        req = urllib.request.Request(
            url,
            headers={
                "Authorization": f"Token {token}",
                "Accept":        "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
                return data.get("results", [])
        except urllib.error.HTTPError as e:
            print(f"ERROR fetching devices from NetBox: HTTP {e.code} {e.reason}", flush=True)
            sys.exit(1)
        except Exception as e:
            print(f"ERROR fetching devices from NetBox: {e}", flush=True)
            sys.exit(1)

    def build_targets(devices, community):
        targets = []
        skipped = 0
        # Auth profile name is derived from the community so the snmp.yml auth
        # section stays in sync. Currently only one community is supported;
        # the profile name is always "snmp_community" (static entry in snmp.yml).
        auth_profile = "snmp_community"
        for device in devices:
            primary_ip = device.get("primary_ip")
            if not primary_ip:
                print(f"SKIP {device['name']}: no primary IP assigned in NetBox", flush=True)
                skipped += 1
                continue
            # Strip prefix length: "192.168.1.1/24" → "192.168.1.1"
            ip = primary_ip["address"].split("/")[0]
            cf     = device.get("custom_fields") or {}
            module = (cf.get("snmp_module") or "").strip() or DEFAULT_MODULE
            role   = ((device.get("device_role") or {}).get("name") or "unknown")
            site   = ((device.get("site")        or {}).get("name") or "unknown")
            targets.append({
                "targets": [ip],
                "labels": {
                    "device_name":    device["name"],
                    "device_role":    role,
                    "site":           site,
                    "__param_module": module,
                    "__param_auth":   auth_profile,
                },
            })
        if skipped:
            print(f"Skipped {skipped} device(s) with no primary IP.", flush=True)
        return targets

    def main():
        token     = read_file(TOKEN_FILE, "NetBox API token")
        community = read_file(COMMUNITY_FILE, "SNMP community")
        devices   = fetch_devices(token)
        sd        = build_targets(devices, community)
        payload   = json.dumps(sd, indent=2)
        tmp       = OUTPUT_FILE + ".tmp"
        with open(tmp, "w") as f:
            f.write(payload)
        os.rename(tmp, OUTPUT_FILE)
        print(f"Wrote {len(sd)} SNMP target(s) to {OUTPUT_FILE}", flush=True)

    main()
  '';

  # Webhook bridge: translates Alertmanager POST payloads to Apprise API format.
  # Alertmanager sends {"receiver":...,"alerts":[...]} but Apprise needs
  # {"body":"...","title":"...","type":"...","tag":"..."}.
  alertmanagerApprisebridge = pkgs.writeScript "alertmanager-apprise-bridge" ''
    #!${pkgs.python3}/bin/python3
    import json
    import urllib.request
    from http.server import HTTPServer, BaseHTTPRequestHandler

    APPRISE_URL = "https://apprise.xrs444.net/notify/apprise"
    APPRISE_TAG = "alerts"

    class Bridge(BaseHTTPRequestHandler):
        def do_POST(self):
            try:
                length = int(self.headers.get("Content-Length", 0))
                payload = json.loads(self.rfile.read(length))
                status = payload.get("status", "firing")
                alerts = payload.get("alerts", [])
                if not alerts:
                    self.send_response(200)
                    self.end_headers()
                    return
                lines = []
                for a in alerts:
                    name = a["labels"].get("alertname", "Unknown")
                    inst = a["labels"].get("instance", "")
                    summ = a["annotations"].get("summary", "")
                    desc = a["annotations"].get("description", "")
                    line = f"• {name}"
                    if inst:
                        line += f" [{inst}]"
                    if summ:
                        line += f": {summ}"
                    if desc and desc != summ:
                        line += f"\n  {desc}"
                    lines.append(line)
                if status == "resolved":
                    title = f"[RESOLVED] {len(alerts)} alert(s)"
                    msg_type = "success"
                else:
                    sev = alerts[0]["labels"].get("severity", "warning")
                    title = f"[FIRING] {len(alerts)} alert(s)"
                    msg_type = "failure" if sev == "critical" else "warning"
                body = json.dumps({
                    "title": title,
                    "body": "\n".join(lines),
                    "type": msg_type,
                    "tag": APPRISE_TAG,
                }).encode()
                req = urllib.request.Request(
                    APPRISE_URL, data=body,
                    headers={"Content-Type": "application/json"}, method="POST"
                )
                with urllib.request.urlopen(req, timeout=10) as r:
                    r.read()
                self.send_response(200)
                self.end_headers()
            except Exception as e:
                print(f"Bridge error: {e}", flush=True)
                self.send_response(500)
                self.end_headers()
        def log_message(self, fmt, *args):
            print(fmt % args, flush=True)

    HTTPServer(("127.0.0.1", 9099), Bridge).serve_forever()
  '';
in
{
  config = lib.mkIf isMonitoringServer {
    # Deliver the HA long-lived access token via sops-nix.
    # The file homeassistant-prometheus.yaml must be encrypted before first deploy:
    #   sops -e -i secrets/homeassistant-prometheus.yaml
    sops.secrets."homeassistant-token" = {
      sopsFile = ../../../secrets/homeassistant-prometheus.yaml;
      key = "token";
      owner = "prometheus";
      mode = "0400";
    };

    # NetBox read-only API token for SNMP device discovery.
    # Create and encrypt the secrets file before first deploy:
    #   echo 'token: <your-netbox-read-only-api-token>' > nix/secrets/netbox-prometheus.yaml
    #   sops -e -i nix/secrets/netbox-prometheus.yaml
    # The token is read by the netbox-snmp-discovery service (not by Prometheus directly).
    sops.secrets."netbox-token" = {
      sopsFile = ../../../secrets/netbox-prometheus.yaml;
      key = "token";
      owner = "root";
      group = "prometheus";
      mode = "0440";
    };

    # SNMP community string from the same secrets file (key: snmp).
    # The discovery script passes this as the community for SNMPv2c auth.
    sops.secrets."snmp-community" = {
      sopsFile = ../../../secrets/netbox-prometheus.yaml;
      key = "snmp";
      owner = "root";
      group = "prometheus";
      mode = "0440";
    };

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

        # Bird BGP exporter - all nodes (Tailscale exit + K8s gateway)
        {
          job_name = "bird";
          static_configs = [
            {
              targets = birdExitTargets;
              labels = { role = "tailscale-exit"; };
            }
            {
              targets = birdGatewayTargets;
              labels = { role = "k8s-gateway"; };
            }
          ];
        }

        # Generic network devices (Firewalla, Omada, etc.)
        # (replaced by the NetBox-driven snmp job below — see netbox-snmp-discovery timer)

        # SNMP — devices discovered from NetBox (tag: snmp-monitor)
        # Targets written to /var/lib/prometheus/snmp-sd.json by the
        # netbox-snmp-discovery timer.  The discovery script sets:
        #   __param_module  — from NetBox custom field snmp_module (default: if_mib)
        #   device_name     — used as the instance label
        #   device_role / site — informational labels
        # All devices use the 'public_v2' auth profile (SNMPv2c, community: public).
        # To add a device with a non-default community:
        #   1. Add a new auth entry to the snmp.yml in exporters.nix.
        #   2. Set __param_auth in the discovery script (snmp_community custom field).
        {
          job_name = "snmp";
          scrape_interval = "60s";
          scrape_timeout = "30s";
          metrics_path = "/snmp";
          params = {
            # Global auth profile — SNMPv2c community 'public'.
            # Overridden per-device via __param_auth label in file_sd if needed.
            auth = [ "public_v2" ];
          };
          file_sd_configs = [
            {
              files = [ "/var/lib/prometheus/snmp-sd.json" ];
              refresh_interval = "5m";
            }
          ];
          relabel_configs = [
            # Forward the device IP as the SNMP ?target= parameter
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            # Use the NetBox device name as the Prometheus instance label
            {
              source_labels = [ "device_name" ];
              target_label = "instance";
            }
            # Default __param_module to if_mib if the discovery script didn't set it
            {
              source_labels = [ "__param_module" ];
              regex = "";
              replacement = "if_mib";
              target_label = "__param_module";
            }
            # Route all SNMP scrapes through the local SNMP exporter
            {
              target_label = "__address__";
              replacement = "localhost:9116";
            }
          ];
        }

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
            credentials_file = config.sops.secrets."homeassistant-token".path;
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
          metrics_path = "/metrics";
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
              targets = [ "172.20.3.10:30113" ];
              labels = {
                cluster = "home-k8s";
                component = "lidarr";
              };
            }
          ];
        }

        # Kubernetes - Windmill automation engine metrics (CE: /metrics on port 8000, via NodePort)
        {
          job_name = "windmill";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "172.20.3.10:30120" ];
              labels = {
                cluster = "home-k8s";
                component = "windmill";
              };
            }
          ];
        }

        # Kubernetes - PowerDNS Authoritative (lab DNS) metrics (via NodePort 30121)
        {
          job_name = "powerdns";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "172.20.3.10:30121" ];
              labels = {
                cluster = "home-k8s";
                component = "powerdns";
                namespace = "xlab-mgmt";
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
              name = "zfs_replication_alerts";
              interval = "60s";
              rules = [
                {
                  alert = "ZFSReplicationFailed";
                  expr = "node_systemd_unit_state{name=~\"zfs-replication-.*\\\\.service\",state=\"failed\"} == 1";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "ZFS replication job failed on {{ $labels.instance }}";
                    description = "Systemd unit {{ $labels.name }} on {{ $labels.instance }} is in failed state.";
                  };
                }
                {
                  alert = "ZFSReplicationStale";
                  expr = "(time() - node_systemd_unit_state_change_timestamp_seconds{name=~\"zfs-replication-.*\\\\.service\"}) > 7200";
                  for = "30m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "ZFS replication job has not run in over 2 hours on {{ $labels.instance }}";
                    description = "Unit {{ $labels.name }} last changed state {{ $value | humanizeDuration }} ago. Expected to run hourly.";
                  };
                }
                {
                  alert = "ZFSScrubRunningLong";
                  expr = "zfs_pool_scrub_errors == 0 and zfs_pool_health == 0";
                  for = "24h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "ZFS pool {{ $labels.pool }} scrub has been running for over 24 hours on {{ $labels.instance }}";
                    description = "22TB drives take longer to scrub. This alert fires if a scrub spans more than 24 hours.";
                  };
                }
              ];
            }
            {
              name = "offsite_backup_alerts";
              interval = "60s";
              rules = [
                {
                  alert = "OffsiteBackupFailed";
                  expr = "node_systemd_unit_state{name=~\"restic-backups-.*\\\\.service\",state=\"failed\"} == 1";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Offsite restic backup failed on {{ $labels.instance }}";
                    description = "Systemd unit {{ $labels.name }} on {{ $labels.instance }} is in failed state.";
                  };
                }
                {
                  alert = "OffsiteBackupStale";
                  expr = "(time() - node_systemd_unit_state_change_timestamp_seconds{name=~\"restic-backups-.*\\\\.service\"}) > 172800";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Offsite backup has not run in over 48 hours on {{ $labels.instance }}";
                    description = "Unit {{ $labels.name }} last changed state {{ $value | humanizeDuration }} ago. Expected to run daily.";
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
                  expr = "count(up{job=\"bird\",role=\"tailscale-exit\"} == 0) == 2";
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
                  alert = "K8sGatewayBGPAllDown";
                  expr = "count(up{job=\"bird\",role=\"k8s-gateway\"} == 0) == 3";
                  for = "3m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "All K8s gateway BGP nodes are down";
                    description = "Bird exporter is unreachable on all three xsvr nodes. K8s LoadBalancer service reachability may be impaired.";
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
                  # robustness: 0=unknown, 1=healthy, 2=degraded, 3=faulted
                  # unknown (0) is normal for detached volumes — only alert on 2 and 3
                  expr = "longhorn_volume_robustness >= 2";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Longhorn volume {{ $labels.volume }} is degraded";
                    description = "Longhorn volume {{ $labels.volume }} has robustness state {{ $value }} (2=degraded, 3=faulted).";
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
                # Bridge on localhost translates Alertmanager JSON → Apprise format
                url = "http://127.0.0.1:9099";
                send_resolved = true;
              }
            ];
          }
          {
            name = "critical";
            webhook_configs = [
              {
                # Bridge on localhost translates Alertmanager JSON → Apprise format
                url = "http://127.0.0.1:9099";
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

    # Fix permissions on manually-placed k8s token file so
    # the prometheus user (not thomas-local) can read it.
    # (homeassistant-token is now managed by sops-nix with owner = "prometheus")
    system.activationScripts.prometheus-token-permissions = {
      deps = [ "users" ];
      text = ''
        if [ -f /var/lib/prometheus/k8s-token ]; then
          chown prometheus:prometheus /var/lib/prometheus/k8s-token
          chmod 600 /var/lib/prometheus/k8s-token
        fi
      '';
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

    # Alertmanager → Apprise webhook bridge
    # Translates Alertmanager JSON payloads to Apprise API format,
    # then forwards to Apprise with tag=alerts (routes to xrs444 ntfy topic).
    systemd.services.alertmanager-apprise-bridge = {
      description = "Alertmanager to Apprise webhook bridge";
      wantedBy = [ "multi-user.target" ];
      after = [ "alertmanager.service" ];
      serviceConfig = {
        ExecStart = "${alertmanagerApprisebridge}";
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = true;
      };
    };

    # NetBox → Prometheus SNMP service discovery
    # Queries NetBox API for devices tagged 'snmp-monitor', writes
    # /var/lib/prometheus/snmp-sd.json consumed by the snmp file_sd_configs job.
    # Runs once immediately on boot, then every 5 minutes via the timer below.
    systemd.services.netbox-snmp-discovery = {
      description = "NetBox SNMP target discovery for Prometheus";
      after = [ "network-online.target" "prometheus.service" ];
      wants = [ "network-online.target" ];
      # Also run once at boot so the file exists before Prometheus starts
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${netboxSnmpDiscovery}";
        # Run as the prometheus user so it can write to /var/lib/prometheus/
        User = "prometheus";
        Group = "prometheus";
      };
    };

    systemd.timers.netbox-snmp-discovery = {
      description = "Run NetBox SNMP discovery every 5 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        Unit = "netbox-snmp-discovery.service";
      };
    };
  };
}

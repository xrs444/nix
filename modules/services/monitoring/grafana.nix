# Summary: Grafana configuration with Prometheus/Loki datasources and folder-based dashboard provisioning.
{
  hostname,
  hostRoles ? [ ],
  lib,
  ...
}:
let
  isGrafanaServer = lib.elem "grafana-server" hostRoles;

  # All dashboard JSON files in ./dashboards/
  allDashboards = lib.filesystem.listFilesRecursive ./dashboards;
  jsonDashboards = lib.filter (
    f: lib.hasSuffix ".json" (builtins.baseNameOf (toString f))
  ) allDashboards;

  # Map dashboard basename (no extension) to Grafana folder name
  folderFor =
    name:
    if
      lib.elem name [
        "overall-system-status"
        "server-health-overview"
        "server-detail"
        "node-exporter-full"
        "zfs"
        "alertmanager"
        "prometheus-stats"
      ]
    then
      "System"
    else if
      lib.elem name [
        "kubernetes-cluster-overview"
        "kubernetes-cluster-monitoring"
        "kubernetes-apiserver"
        "kubernetes-pod-overview"
        "talos-node-detail"
        "deployments"
      ]
    then
      "Kubernetes"
    else if name == "network-devices" then
      "Network"
    else if
      lib.elem name [
        "app-traefik"
        "app-cilium"
        "app-cert-manager"
        "app-loki"
        "app-longhorn"
        "app-spegel"
        "app-kube-state-metrics"
      ]
    then
      "Infrastructure"
    else if
      lib.elem name [
        "app-sonarr"
        "app-radarr"
        "app-lidarr"
        "app-jellyfin"
        "app-audiobookshelf"
        "app-tdarr"
      ]
    then
      "Media"
    else
      "Applications";

  # Folder name -> sanitized subdirectory name
  folderToDir = {
    "System" = "system";
    "Kubernetes" = "kubernetes";
    "Network" = "network";
    "Infrastructure" = "infrastructure";
    "Media" = "media";
    "Applications" = "applications";
  };

  allFolders = [
    "System"
    "Kubernetes"
    "Network"
    "Infrastructure"
    "Media"
    "Applications"
  ];

  # Generate copy commands for a given folder
  copyScriptForFolder =
    folder:
    let
      dir = folderToDir.${folder};
      filesForFolder = lib.filter (
        f:
        let
          name = lib.removeSuffix ".json" (builtins.baseNameOf (toString f));
        in
        folderFor name == folder
      ) jsonDashboards;
    in
    ''
      mkdir -p /var/lib/grafana/dashboards/${dir}
      ${lib.concatMapStringsSep "\n" (f: "cp ${f} /var/lib/grafana/dashboards/${dir}/") filesForFolder}
    '';
in
{
  config = lib.mkIf isGrafanaServer {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = "${hostname}";
        };

        security = {
          admin_user = "admin";
          # admin_password should be set via environment file
        };

        "auth.anonymous" = {
          enabled = false;
        };
      };

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:9090";
            isDefault = true;
            uid = "000000001";
            jsonData = {
              timeInterval = "15s";
            };
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "https://loki.xrs444.net";
            uid = "000000002";
            jsonData = {
              maxLines = 1000;
              timeout = 60;
            };
          }
        ];

        # Folder-based dashboard provisioning — one provider per folder
        dashboards.settings = {
          apiVersion = 1;
          providers = lib.map (folder: {
            name = folder;
            orgId = 1;
            folder = folder;
            folderUid = lib.toLower (builtins.replaceStrings [ " " ] [ "-" ] folder);
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 30;
            allowUpdating = true;
            options = {
              path = "/var/lib/grafana/dashboards/${folderToDir.${folder}}";
            };
          }) allFolders;
        };
      };
    };

    # Ensure Grafana starts after Prometheus
    systemd.services.grafana.after = [ "prometheus.service" ];

    # Populate dashboard subdirectories from nix store
    systemd.services.grafana-setup-dashboards = {
      description = "Setup Grafana Dashboards";
      wantedBy = [ "grafana.service" ];
      before = [ "grafana.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${lib.concatMapStringsSep "\n" copyScriptForFolder allFolders}
        chown -R grafana:grafana /var/lib/grafana/dashboards
      '';
    };
  };
}

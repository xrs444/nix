# Summary: Network UPS Tools (NUT) for the USB UPS attached to xdt1-t —
# standalone mode (driver + upsd + upsmon all local) plus a Prometheus
# nut_exporter so charge/runtime/status reach the k8s monitoring stack.
{
  hostname,
  config,
  lib,
  ...
}:
let
  isXdt1t = hostname == "xdt1-t";
in
{
  config = lib.mkIf isXdt1t {
    sops.secrets."nut-upsmon-password" = {
      sopsFile = ../../../secrets/nut-upsmon.yaml;
      key = "nut_upsmon_password";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    power.ups = {
      enable = true;
      mode = "standalone";

      ups.xdt1t-ups = {
        driver = "usbhid-ups";
        port = "auto";
        description = "USB UPS attached to xdt1-t";
      };

      users.upsmon = {
        passwordFile = config.sops.secrets."nut-upsmon-password".path;
        upsmon = "primary";
      };

      # upsd.enable / upsmon.enable both default to true under mode =
      # "standalone" — no need to set them explicitly.
      upsmon.monitor.xdt1t-ups = {
        system = "xdt1t-ups@localhost";
        powerValue = 1;
        user = "upsmon";
        type = "primary";
      };
    };

    # Prometheus exporter — talks to the local upsd over the NUT protocol.
    # nutServer defaults to 127.0.0.1 (correct — upsd is local); no
    # nutUser/passwordPath needed since default NUT configs permit
    # unauthenticated variable reads, and this exporter only reads.
    #
    # Serves UPS metrics on /ups_metrics, NOT /metrics (that path is the
    # exporter's own process telemetry) — see the scrape job's metrics_path
    # in flux's prometheus-additional-scrape-configs.
    #
    # nutVariables overrides the binary's built-in default list to add
    # battery.runtime (minutes remaining — the value the shutdown-trigger
    # automation actually keys off) and battery.charge.low (the UPS's own
    # configured low-battery threshold, for context in alerts/dashboards).
    services.prometheus.exporters.nut = {
      enable = true;
      port = 9199;
      listenAddress = "0.0.0.0";
      openFirewall = false; # opened explicitly below alongside the other exporters
      nutVariables = [
        "battery.charge"
        "battery.charge.low"
        "battery.runtime"
        "battery.voltage"
        "battery.voltage.nominal"
        "input.voltage"
        "input.voltage.nominal"
        "ups.load"
        "ups.status"
      ];
    };

    networking.firewall.interfaces.enp8s0.allowedTCPPorts = [
      9199 # nut_exporter
    ];
  };
}

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
  # Not secret — just the SNMPv3 username paired with the sops-managed
  # auth/priv passphrases above.
  rwSnmpv3Username = "nut-snmpv3-admin";
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

    # Read/write SNMPv3 credentials for the snmp-ups driver's admin actions
    # (self-test, beeper, delayed shutdown) against the rack UPS xups.lan —
    # distinct from snmp-exporter's read-only SNMPv3 creds in the flux repo.
    # The nut NixOS module has no secrets-file mechanism for driver-level
    # directives (unlike users.*.passwordFile), so these land in ups.conf as
    # placeholder tokens and get substituted by an activation script below,
    # after setupSecrets — keeps the real passphrases out of the Nix store.
    sops.secrets."nut-snmpv3-rw-auth-password" = {
      sopsFile = ../../../secrets/nut-upsmon.yaml;
      key = "nut_snmpv3_rw_auth_password";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    sops.secrets."nut-snmpv3-rw-priv-password" = {
      sopsFile = ../../../secrets/nut-upsmon.yaml;
      key = "nut_snmpv3_rw_priv_password";
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

      # Rack UPS (Eaton SPX2200, xups.lan) — network card only offers SNMPv1
      # or v3, no v2c. mibs=auto lets NUT prefer Eaton's vendor MIB (richer
      # instant commands — test, beeper, delayed shutdown) over plain
      # RFC1628 UPS-MIB when available; that's the point of a separate RW
      # credential vs. snmp-exporter's read-only one.
      ups.xups-rack = {
        driver = "snmp-ups";
        port = "xups.lan";
        description = "Eaton SPX2200 rack UPS (SNMPv3, admin)";
        directives = [
          "mibs = auto"
          "snmp_version = v3"
          "secLevel = authPriv"
          "secName = ${rwSnmpv3Username}"
          "authProtocol = SHA"
          "authPassword = @SNMPV3_RW_AUTHPASS@"
          "privProtocol = AES"
          "privPassword = @SNMPV3_RW_PRIVPASS@"
        ];
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

    # environment.etc reconciles /etc/nut/ups.conf to a fresh symlink into
    # /nix/store (world-readable) on every activation, so this runs after
    # both "setupSecrets" and "etc" each time: swap the symlink for a real
    # file, substitute the RW SNMPv3 placeholders with the sops-decrypted
    # passphrases, then lock permissions to root only. Rotating the sops
    # secret values alone (no other ups.conf change) won't bump the
    # environment.etc store path, so upsdrv.service won't auto-restart to
    # pick up new creds after a rotation — same caveat as the Asterisk/
    # Grandstream secret substitution in phone-config-nginx/xpbx1.nix.
    system.activationScripts.nutSnmpv3RwSecret = {
      deps = [
        "setupSecrets"
        "etc"
      ];
      text = ''
        UPS_CONF=/etc/nut/ups.conf
        if [ -L "$UPS_CONF" ]; then
          REAL=$(readlink -f "$UPS_CONF")
          rm -f "$UPS_CONF"
          cp "$REAL" "$UPS_CONF"
        fi
        sed -i \
          -e "s/@SNMPV3_RW_AUTHPASS@/$(cat ${config.sops.secrets."nut-snmpv3-rw-auth-password".path})/" \
          -e "s/@SNMPV3_RW_PRIVPASS@/$(cat ${config.sops.secrets."nut-snmpv3-rw-priv-password".path})/" \
          "$UPS_CONF"
        chown root:root "$UPS_CONF"
        chmod 600 "$UPS_CONF"
      '';
    };
  };
}

# Summary: Asterisk PBX service configuration module
{
  lib,
  pkgs,
  hostRoles ? [ ],
  hostname,
  ...
}:
let
  isAsteriskHost = lib.elem "asterisk" hostRoles;
in
{
  imports = [ ./extensions.nix ./pjsip.nix ];

  config = lib.mkIf isAsteriskHost {
    # Ensure Asterisk logs are captured by Promtail
    # Asterisk logs to /var/log/asterisk/ by default
    services.promtail.configuration.scrape_configs = lib.mkAfter [
      {
        job_name = "asterisk-logs";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "asterisk";
              host = hostname;
              __path__ = "/var/log/asterisk/*.log";
            };
          }
        ];
      }
    ];
    environment.systemPackages = with pkgs; [
      asterisk
    ];

    # Enable Asterisk PBX
    services.asterisk = {
      enable = true;

      # Configuration files
      # These can be extended in host-specific configs for custom extensions, DPMA, etc.
      confFiles = {
        # Basic asterisk.conf
        "asterisk.conf" = ''
          [directories]
          astetcdir => /etc/asterisk
          astmoddir => ${pkgs.asterisk}/lib/asterisk/modules
          astvarlibdir => /var/lib/asterisk
          astdatadir => /var/lib/asterisk
          astagidir => /var/lib/asterisk/agi-bin
          astspooldir => /var/spool/asterisk
          astrundir => /run/asterisk
          astlogdir => /var/log/asterisk

          [options]
          verbose = 3
          debug = 3
        '';

        # Basic modules.conf - autoload all modules, suppressing those not built/available
        "modules.conf" = ''
          [modules]
          autoload = yes

          ; Modules not built or missing dependencies in this Nix Asterisk package
          noload => cdr_sqlite3_custom
          noload => cdr_manager
          noload => app_alarmreceiver
          noload => app_followme
          noload => app_festival
          noload => pbx_ael
          noload => pbx_lua
          noload => res_hep_rtcp
          noload => res_hep_pjsip

          ; Modules requiring missing config files (xmpp.conf, pjsip_notify.conf, etc.)
          noload => res_xmpp
          noload => chan_motif
          noload => res_pjsip_notify
          noload => res_stun_monitor
          noload => res_phoneprov
          noload => res_pjsip_phoneprov_provider

          ; CEL/CDR modules not in use
          noload => cel_sqlite3_custom
          noload => cel_custom

          ; Deprecated modules scheduled for removal
          noload => res_adsi
          noload => app_adsiprog
          noload => app_getcpeid

          ; Fax not in use
          noload => res_fax
        '';

        # Enable the built-in HTTP server (required by res_prometheus)
        "http.conf" = ''
          [general]
          enabled = yes
          bindaddr = 0.0.0.0
          bindport = 8088
        '';

        # Prometheus metrics endpoint — scraped by Prometheus on port 8088
        "prometheus.conf" = ''
          [general]
          enabled = yes
          uri = metrics
        '';

        # Basic pjsip.conf for SIP configuration
        "pjsip.conf" = ''
          ; PJSIP Configuration
          ; Host-specific phone configurations should be added via host config

          [transport-udp]
          type = transport
          protocol = udp
          bind = 0.0.0.0:5060
        '';

        # Stub configs to suppress missing-file warnings
        "pjproject.conf" = ''
          [startup]
        '';

        "res_http_media_cache.conf" = ''
          [general]
        '';

        "voicemail.conf" = ''
          [general]

          [zonemessages]
        '';

        "queuerules.conf" = ''
          ; No penalty rules defined
        '';

        # RTP configuration
        "rtp.conf" = ''
          [general]
          rtpstart = 10000
          rtpend = 20000
        '';
      };
    };

    # Open firewall ports for Asterisk
    networking.firewall = {
      allowedTCPPorts = [
        5060 # SIP
        8088 # Asterisk HTTP/WebSocket
      ];
      allowedUDPPorts = [
        5060 # SIP
      ] ++ (lib.range 10000 20000); # RTP port range
    };
  };
}

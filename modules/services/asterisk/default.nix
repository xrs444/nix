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
          astmoddir => /var/lib/asterisk/modules
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

        # Basic modules.conf - enable only necessary modules
        "modules.conf" = ''
          [modules]
          autoload = no

          ; Core modules
          load => res_musiconhold.so
          load => res_rtp_asterisk.so
          load => res_pjsip.so
          load => res_pjsip_session.so
          load => chan_pjsip.so

          ; Applications
          load => app_dial.so
          load => app_echo.so
          load => app_playback.so
          load => app_voicemail.so

          ; Codecs
          load => codec_ulaw.so
          load => codec_alaw.so
          load => codec_gsm.so

          ; Formats
          load => format_gsm.so
          load => format_pcm.so
          load => format_wav.so
          load => format_wav_gsm.so

          ; PBX
          load => pbx_config.so
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

        # Basic extensions.conf for dialplan
        "extensions.conf" = ''
          ; Dialplan configuration
          ; Host-specific extensions should be added via host config

          [general]
          static = yes
          writeprotect = no

          [default]
          ; Extensions will be configured in host-specific configs
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

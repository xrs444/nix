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
  imports = [ ./extensions.nix ];

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

        # Basic modules.conf - autoload all modules
        "modules.conf" = ''
          [modules]
          autoload = yes
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

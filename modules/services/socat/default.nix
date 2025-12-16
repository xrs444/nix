# Summary: Socat service module for bidirectional data relay between network sockets, files, or processes.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.socat;
  
  # Generate a systemd service for each socat instance
  mkSocatService = name: instanceCfg: {
    description = "Socat relay: ${name}";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.socat}/bin/socat ${lib.concatStringsSep " " instanceCfg.options} ${instanceCfg.source} ${instanceCfg.destination}";
      Restart = "always";
      RestartSec = "5s";
      User = instanceCfg.user;
      Group = instanceCfg.group;
    };
  };
in
{
  options.services.socat = {
    enable = lib.mkEnableOption "socat relay service";
    
    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            description = "Source address specification (e.g., TCP-LISTEN:8080,fork or STDIO)";
            example = "TCP-LISTEN:8080,fork,reuseaddr";
          };
          
          destination = lib.mkOption {
            type = lib.types.str;
            description = "Destination address specification (e.g., TCP:remote-host:80 or EXEC:command)";
            example = "TCP:192.168.1.100:80";
          };
          
          options = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional socat command-line options";
            example = [ "-d" "-d" ];
          };
          
          user = lib.mkOption {
            type = lib.types.str;
            default = "nobody";
            description = "User to run the socat process as";
          };
          
          group = lib.mkOption {
            type = lib.types.str;
            default = "nogroup";
            description = "Group to run the socat process as";
          };
        };
      });
      default = {};
      description = "Named socat relay instances to run as systemd services";
      example = lib.literalExpression ''
        {
          audio-stream = {
            source = "TCP-LISTEN:8000,fork,reuseaddr";
            destination = "TCP:audio-server:8000";
            options = [ "-d" "-d" ];
          };
        }
      '';
    };
  };
  
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.socat ];
    
    systemd.services = lib.mapAttrs' (name: instanceCfg:
      lib.nameValuePair "socat-${name}" (mkSocatService name instanceCfg)
    ) cfg.instances;
  };
}

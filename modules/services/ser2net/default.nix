# Summary: Ser2net service module for presenting USB serial devices on the network.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.ser2net;

in
{
  options.services.ser2net = {
    enable = mkEnableOption "ser2net serial to network service";

    port = mkOption {
      type = types.port;
      default = 2000;
      description = "TCP port to listen on";
    };

    device = mkOption {
      type = types.str;
      example = "/dev/ttyUSB0";
      description = "Serial device path to expose";
    };

    baudrate = mkOption {
      type = types.int;
      default = 115200;
      description = "Baud rate for the serial device";
    };

    user = mkOption {
      type = types.str;
      default = "root";
      description = "User to run ser2net as";
    };

    group = mkOption {
      type = types.str;
      default = "dialout";
      description = "Group to run ser2net as";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional ser2net configuration";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.device != "";
        message = "services.ser2net.device must be set when ser2net is enabled";
      }
    ];

    # Generate ser2net.yaml configuration
    environment.etc."ser2net/ser2net.yaml".text = ''
      %YAML 1.1
      ---
      define: &banner \r\nser2net port \p device \d [\s] (NixOS)\r\n\r\n

      connection: &con01
        accepter: tcp,${toString cfg.port}
        enable: on
        options:
          banner: *banner
          kickolduser: true
          telnet-brk-on-sync: true
        connector: serialdev,
                  ${cfg.device},
                  ${cfg.baudrate}n81,local
    '';

    environment.systemPackages = [ pkgs.ser2net ];

    systemd.services.ser2net = {
      description = "Serial to Network Proxy";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.ser2net}/bin/ser2net -n -c /etc/ser2net/ser2net.yaml";
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/dev" ];
      };
    };

    # Ensure dialout group exists for serial device access
    users.groups.dialout = { };
  };
}

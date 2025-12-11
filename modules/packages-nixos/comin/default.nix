{ config, lib, pkgs, ... }:

let
  cfg = config.services.comin-custom;
  isXsvr3 = config.networking.hostName == "xsvr3";
in

with lib;

{
  options.services.comin-custom = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable custom Comin configuration";
    };
  };

  config = mkIf cfg.enable {
    services.comin = {
      enable = true;
      hostname = config.networking.hostName;  # Explicitly set the hostname
      remotes = [
        {
          name = "origin";
          url = "https://github.com/xrs444/nix.git";
          branches.main.name = "main";
        }
      ];
      postDeploymentCommand = lib.mkIf isXsvr3 "/var/lib/comin/repository/scripts/build-and-cache-xsvr1-hosts.sh";
    };
    systemd.services.comin.serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
  };
}

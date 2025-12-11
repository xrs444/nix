{
  config,
  lib,
  ...
}:

let
  isXsvr3 = config.networking.hostName == "xsvr3";
in

{
  config = {
    services.comin = {
      enable = true;
      hostname = config.networking.hostName; # Explicitly set the hostname
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

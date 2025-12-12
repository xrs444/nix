{ config, lib, ... }:
{
  config =
    let
      hostName = config.networking.hostName or null;
      isXsvr3 = hostName == "xsvr3";
    in
    {
      services.comin = {
        enable = lib.mkForce true;
        hostname = hostName;
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

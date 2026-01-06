{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      hostName = config.networking.hostName or null;
      isXsvr3 = hostName == "xsvr3";

      # Script to send success notification
      notifySuccess = pkgs.writeShellScript "comin-notify-success" ''
        ${pkgs.curl}/bin/curl -f -s \
          -H "Title: 🔄 Config Applied - ${hostName}" \
          -H "Priority: default" \
          -H "Tags: white_check_mark,gear" \
          -d "Configuration successfully applied on ${hostName} by comin" \
          https://ntfy.xrs444.net/comin
      '';

      # Script to send failure notification
      notifyFailure = pkgs.writeShellScript "comin-notify-failure" ''
        ${pkgs.curl}/bin/curl -f -s \
          -H "Title: ❌ Config Failed - ${hostName}" \
          -H "Priority: high" \
          -H "Tags: x,warning" \
          -d "Configuration deployment failed on ${hostName}. Check systemd logs: journalctl -u comin -n 50" \
          https://ntfy.xrs444.net/comin
      '';
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
        ExecStartPost = notifySuccess;
      };

      # Create a service that runs on comin failure
      systemd.services.comin-failure-notify = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = notifyFailure;
        };
        # Rate limit to prevent notification spam during restart loops
        unitConfig = {
          StartLimitIntervalSec = 300; # 5 minutes
          StartLimitBurst = 1; # Only 1 notification per interval
        };
      };

      # Trigger failure notification when comin fails
      systemd.services.comin.unitConfig = {
        OnFailure = "comin-failure-notify.service";
      };
    };
}

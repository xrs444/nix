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
      isXsvr1 = hostName == "xsvr1";

      # Script to send success notification
      notifySuccess = pkgs.writeShellScript "comin-notify-success" ''
        ${pkgs.curl}/bin/curl -f -s \
          -H "Title: 🔄 Config Applied - ${hostName}" \
          -H "Priority: default" \
          -H "Tags: white_check_mark,gear" \
          -d "Configuration successfully applied on ${hostName} by comin" \
          https://ntfy.xrs444.net/comin
      '';

      # Script to send failure notification with rate limiting
      notifyFailure = pkgs.writeShellScript "comin-notify-failure" ''
        LOCK_FILE="/run/comin-notify-failure.lock"
        RATE_LIMIT_SECONDS=300  # 5 minutes

        # Check if we recently sent a notification
        if [ -f "$LOCK_FILE" ]; then
          LAST_NOTIFY=$(cat "$LOCK_FILE")
          CURRENT_TIME=$(date +%s)
          TIME_DIFF=$((CURRENT_TIME - LAST_NOTIFY))

          if [ $TIME_DIFF -lt $RATE_LIMIT_SECONDS ]; then
            exit 0  # Skip notification, too soon
          fi
        fi

        # Send notification
        if ${pkgs.curl}/bin/curl -f -s \
          -H "Title: ❌ Config Failed - ${hostName}" \
          -H "Priority: high" \
          -H "Tags: x,warning" \
          -d "Configuration deployment failed on ${hostName}. Check systemd logs: journalctl -u comin -n 50" \
          https://ntfy.xrs444.net/comin; then
          # Record timestamp if successful
          date +%s > "$LOCK_FILE"
        fi
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
        postDeploymentCommand = lib.mkIf isXsvr1 "/var/lib/comin/repository/scripts/build-and-cache-xsvr1-hosts.sh";
      };

      systemd.services.comin.serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        # Use "-" prefix to allow notification to fail without affecting service status
        ExecStartPost = "-${notifySuccess}";
        # Allow time for git operations to complete
        TimeoutStopSec = "60s";
        # Ensure clean shutdown
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };

      # Create a service that runs on comin failure
      systemd.services.comin-failure-notify = {
        description = "Send notification when comin fails";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = notifyFailure;
          RemainAfterExit = false;
        };
      };

      # Trigger failure notification when comin fails
      systemd.services.comin.unitConfig = {
        OnFailure = "comin-failure-notify.service";
      };
    };
}

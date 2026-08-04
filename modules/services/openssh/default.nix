# Summary: NixOS module for OpenSSH, enables SSH service, fail2ban (with an
# Apprise/ntfy ban-notification action), and configures firewall settings.
{ pkgs, ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Custom fail2ban action: POST an alert to Apprise (-> ntfy, tag "alerts" ->
  # xrs444's topic) whenever a jail bans an IP. actionunban is intentionally
  # empty — we only alert on lockout, not release. Absolute curl path because
  # fail2ban's systemd unit runs with a restricted PATH.
  environment.etc."fail2ban/action.d/apprise-ntfy.local".text = ''
    [Definition]
    actionstart =
    actionstop =
    actioncheck =
    actionunban =
    actionban = ${pkgs.curl}/bin/curl -f --http1.1 --max-time 10 -X POST https://apprise.xrs444.net/notify/apprise -H "Content-Type: application/json" -d '{"title":"fail2ban: <ip> banned on <fq-hostname>","body":"Jail <name> banned <ip> after <failures> failures (bantime <bantime>s).","type":"warning","tag":"alerts"}'
  '';

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    # Short initial ban (10m) so a client offering several SSH-agent keys in one
    # connection attempt (each rejected key = one failed-auth log line) doesn't
    # lock itself out for an hour. bantime-increment still escalates for anyone
    # actually hammering the server (repeat bans within maxtime climb 10m -> ... -> 168h).
    bantime = "10m";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
    };
    jails.sshd.settings = {
      enabled = true;
      filter = "sshd";
      maxretry = 10;
      # Keep the default nftables ban action and append the Apprise notification.
      action = ''
        %(action_)s
        apprise-ntfy
      '';
    };
  };

}

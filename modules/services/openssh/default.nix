# Summary: NixOS module for OpenSSH, enables SSH service and configures authentication and firewall settings.
{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

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
    };
  };

}

{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  allHosts = [ "xsvr1" "xsvr2" "xsvr3" "xcomm1" "xts1" "xts2" ];
  kanidmNodes = [ "xsvr1" "xsvr2""xsvr3"];
  domain = "xrs444.net";
  isPrimaryServer = hostname == "xsvr1";
  isKanidmServer = lib.elem hostname kanidmNodes;
in

{
  # SOPS secrets for Cloudflare (only on primary)
  sops.secrets = lib.mkIf isPrimaryServer {
    cloudflare_dns_api_token = {
      sopsFile = ../../../secrets/cloudflare.yaml;
      key = "dns_api_token";
      owner = "acme";
      group = "acme";
      mode = "0400";
    };
  };

  # ACME config: xsvr1 generates all host certs + idm.xrs444.net
  security.acme = lib.mkIf isPrimaryServer {
    acceptTerms = true;
    defaults = {
      email = "admin@${domain}";
      dnsProvider = "cloudflare";
      # Fix: Use DNS_API_TOKEN, not EMAIL+API_KEY
      credentialFiles = {
        "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_dns_api_token.path;
      };
    };
    certs = lib.mkMerge (
      # Host certificates
      (map (h: { "${h}.${domain}" = { extraDomainNames = []; }; }) allHosts)
      ++
      # Kanidm shared certificate
      (lib.optional isKanidmServer {
        "idm.${domain}" = { extraDomainNames = []; };
      })
    );
  };

  # Ensure acme user/group exists everywhere
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    home = "/var/lib/acme";
    createHome = true;
  };
  users.groups.acme = {};

  # Rsync service/timer: all hosts pull certs from xsvr1
  systemd.services.pull-certificates = lib.mkIf (!isPrimaryServer) {
    description = "Pull certificates from xsvr1";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "acme";
      Group = "acme";
    };
    script = ''
      ${pkgs.rsync}/bin/rsync -avz --delete \
        xsvr1.xrs444.net:/var/lib/acme/ \
        /var/lib/acme/
    '';
  };

  systemd.timers.pull-certificates = lib.mkIf (!isPrimaryServer) {
    description = "Pull certificates from xsvr1 every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}
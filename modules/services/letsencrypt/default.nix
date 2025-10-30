{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  # Define which nodes have Kanidm
  kanidmNodes = [ "xsvr1" "xsvr2" ];
  domain = "xrs444.net";
  hasKanidm = lib.elem hostname kanidmNodes;
in

{
  # Let's Encrypt ACME configuration
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "admin@${domain}";
      dnsProvider = "cloudflare";
      credentialsFile = "/var/lib/acme/cloudflare-credentials";
    };
    
    certs = lib.mkMerge [
      # Server-specific certificate
      {
        "${hostname}.${domain}" = {
          extraDomainNames = [];
        };
      }
      
      # IDM certificate only for servers with Kanidm
      (lib.mkIf hasKanidm {
        "idm.${domain}" = {
          extraDomainNames = [];
        };
      })
    ];
  };

  # Create Cloudflare credentials file
  environment.etc."acme-cloudflare-credentials" = {
    text = ''
      # Cloudflare API credentials for ACME DNS challenge
      # You need to set these values with your actual Cloudflare credentials
      # CF_API_EMAIL=your-email@example.com
      # CF_API_KEY=your-global-api-key
      # OR use API token instead of email+key (recommended):
      CF_DNS_API_TOKEN=your-dns-api-token
    '';
    mode = "0400";
    user = "acme";
    group = "acme";
  };

  # Ensure the credentials file is in the right location
  systemd.services.acme-fixperms = {
    description = "Fix ACME credentials permissions";
    wantedBy = [ "multi-user.target" ];
    before = [ "acme-${hostname}.${domain}.service" ] ++ lib.optionals hasKanidm [ "acme-idm.${domain}.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/cp /etc/acme-cloudflare-credentials /var/lib/acme/cloudflare-credentials";
      ExecStartPost = "${pkgs.coreutils}/bin/chown acme:acme /var/lib/acme/cloudflare-credentials";
    };
  };

  # Create acme user and group
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    home = "/var/lib/acme";
    createHome = true;
  };
  users.groups.acme = {};

  # Open port 80 for HTTP-01 challenge (fallback, though we're using DNS-01)
  networking.firewall.allowedTCPPorts = [ 80 ];
}
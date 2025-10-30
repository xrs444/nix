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
  # Configure sops for Cloudflare credentials - specify file per secret
  sops.secrets.cloudflare_api_key = {
    sopsFile = ../../../secrets/cloudflare.yaml;
    key = "service.api.key";
    owner = "acme";
    group = "acme";
    mode = "0400";
  };
  sops.secrets.cloudflare_email = {
    sopsFile = ../../../secrets/cloudflare.yaml;
    key = "service.api.email";
    owner = "acme";
    group = "acme";
    mode = "0400";
  };

  # Let's Encrypt ACME configuration
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "admin@${domain}";
      dnsProvider = "cloudflare";
      environmentFile = pkgs.writeText "cloudflare-env" ''
        CLOUDFLARE_DNS_API_TOKEN_FILE=${config.sops.secrets.cloudflare_api_key.path}
        CLOUDFLARE_EMAIL_FILE=${config.sops.secrets.cloudflare_email.path}
      '';
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
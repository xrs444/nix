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
  # Configure sops for Cloudflare DNS API token and email
  sops.secrets.cloudflare_dns_api_token = {
    sopsFile = ../../../secrets/cloudflare.yaml;
    key = "dns_api_token";
    owner = "acme";
    group = "acme";
    mode = "0400";
  };

  sops.secrets.cloudflare_email = {
    sopsFile = ../../../secrets/cloudflare.yaml;
    key = "email";
    owner = "acme";
    group = "acme";
    mode = "0400";
  };

  # Let's Encrypt ACME configuration
  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "cloudflare";
      environmentFile = pkgs.writeText "cloudflare-env" ''
        CLOUDFLARE_DNS_API_TOKEN_FILE=${config.sops.secrets.cloudflare_dns_api_token.path}
        CLOUDFLARE_EMAIL_FILE=${config.sops.secrets.cloudflare_email.path}
      '';
    };
    
    certs = lib.mkMerge [
      # Server-specific certificate
      {
        "${hostname}.${domain}" = {
          extraDomainNames = [];
          preRun = ''
            export EMAIL="$(cat ${config.sops.secrets.cloudflare_email.path})"
          '';
        };
      }
      
      # IDM certificate only for servers with Kanidm
      (lib.mkIf hasKanidm {
        "idm.${domain}" = {
          extraDomainNames = [];
          preRun = ''
            export EMAIL="$(cat ${config.sops.secrets.cloudflare_email.path})"
          '';
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

}
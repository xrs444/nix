# Summary: NixOS module for Let's Encrypt, manages certificate issuance and renewal for multiple hosts.
{
  config,
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:

let
  domain = "xrs444.net";

  # Role-based configuration from flake.nix host definitions
  isPrimaryServer = lib.elem "letsencrypt-primary" hostRoles;
  isLetsencryptHost = lib.elem "letsencrypt-host" hostRoles || isPrimaryServer;
  isKanidmServer =
    lib.elem "kanidm-server" hostRoles
    || lib.elem "kanidm-primary" hostRoles
    || lib.elem "kanidm-replica" hostRoles;

  # Generate certificates for all letsencrypt hosts
  allHosts = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
    "xcomm1"
    "xts1"
    "xts2"
  ];
  isSdImageBuild =
    pkgs.stdenv.hostPlatform.system ? build && pkgs.stdenv.hostPlatform.system.build ? sdImage;
  # Provide a default for minimalImage if not defined
  minimalImage = if config ? minimalImage then config.minimalImage else false;
in

lib.mkIf (!minimalImage) {
  # SOPS secrets for Cloudflare (only on primary) and acme SSH key (all hosts)
  sops.secrets = lib.mkMerge [
    (lib.mkIf isPrimaryServer {
      cloudflare_dns_api_token = {
        sopsFile = ../../../secrets/cloudflare.yaml;
        key = "dns_api_token";
        owner = "acme";
        group = "acme";
        mode = "0400";
      };
    })
    {
      acme_ssh_key = {
        sopsFile = ../../../secrets/acme.yaml;
        key = "ssh-key";
        owner = "acme";
        group = "acme";
        mode = "0400";
      };
    }
  ];

  # ACME config: xsvr1 generates all host certs + idm.xrs444.net
  security.acme = lib.mkIf isPrimaryServer {
    acceptTerms = true;
    defaults = {
      email = "admin@${domain}";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      credentialsFile = pkgs.writeText "cloudflare-creds" ''
        CLOUDFLARE_DNS_API_TOKEN_FILE=${config.sops.secrets.cloudflare_dns_api_token.path}
        CLOUDFLARE_PROPAGATION_TIMEOUT=300
        CLOUDFLARE_POLLING_INTERVAL=15
        CLOUDFLARE_TTL=120
      '';
      extraLegoFlags = [
        "--dns.resolvers=1.1.1.1:53"
        "--dns.disable-cp"
      ];
    };
    certs = lib.mkMerge (
      # Host certificates
      (map (h: {
        "${h}.${domain}" = {
          extraDomainNames = [ ];
        };
      }) allHosts)
      ++
        # Kanidm shared certificate
        (lib.optional isKanidmServer {
          "idm.${domain}" = {
            extraDomainNames = [ ];
          };
        })
    );
  };

  # Ensure acme user/group exists only on relevant hosts
  users.users = lib.mkMerge [
    (lib.mkIf
      (!isSdImageBuild && (config.sops.secrets ? acme_ssh_key && config.sops.secrets.acme_ssh_key ? text))
      {
        acme = {
          isSystemUser = true;
          group = "acme";
          home = "/var/lib/acme";
          createHome = true;
          openssh.authorizedKeys.keyFiles = [
            (pkgs.writeText "acme-ssh-key" config.sops.secrets.acme_ssh_key.text)
          ];
        };
      }
    )
  ];
  users.groups = lib.mkMerge [
    (lib.mkIf
      (!isSdImageBuild && (config.sops.secrets ? acme_ssh_key && config.sops.secrets.acme_ssh_key ? text))
      {
        acme = { };
      }
    )
  ];

}

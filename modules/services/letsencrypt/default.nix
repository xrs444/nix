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
        format = "string";
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
      (map (h: { "${h}.${domain}" = { extraDomainNames = []; }; }) allHosts)
      ++
      # Kanidm shared certificate
      (lib.optional isKanidmServer {
        "idm.${domain}" = { extraDomainNames = []; };
      })
    );
  };

  # Ensure acme user/group exists only on relevant hosts
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    home = "/var/lib/acme";
    createHome = true;
    openssh.authorizedKeys.keys = [ config.sops.secrets.acme_ssh_key ];
  };
  users.groups.acme = {};


  # Systemd services configuration
  systemd.services = lib.mkMerge [
    # Add ordering to prevent concurrent ACME requests (primary server only)
    (lib.mkIf isPrimaryServer (
      let
        # Create ordered list of services
        hostServices = map (h: "acme-${h}.${domain}.service") allHosts;
        kanidmService = lib.optional isKanidmServer "acme-idm.${domain}.service";
        allServices = hostServices ++ kanidmService;
        
        # Create dependency chain with delays
        orderedServices = lib.imap0 (i: svc:
          lib.nameValuePair svc {
            after = lib.optional (i > 0) (lib.elemAt allServices (i - 1));
            serviceConfig = lib.mkIf (i > 0) {
              ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
            };
          }
        ) allServices;
      in
      lib.listToAttrs orderedServices
    ))

    # Rsync service: all non-primary hosts pull certs from xsvr1
    (lib.mkIf (!isPrimaryServer) {
      pull-certificates = {
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
    })
  ];

  # Rsync timer: all non-primary hosts pull certs hourly
  systemd.timers.pull-certificates = lib.mkIf (!isPrimaryServer) {
    description = "Pull certificates from xsvr1 every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
 };
}
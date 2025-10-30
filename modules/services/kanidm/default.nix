{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  # Only xsvr1 and xsvr2 should run kanidm servers
  isKanidmServer = builtins.elem hostname ["xsvr1" "xsvr2"];
  
  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";
  
  # Check if we're on Darwin (macOS)
  isDarwin = pkgs.stdenv.isDarwin;
in
lib.mkMerge [

  # NixOS server configuration
  (lib.mkIf isKanidmServer {
    # Remove the insecure package allowance since we're using 1.7
    # nixpkgs.config.permittedInsecurePackages = [
    #   "kanidm-1.6.4"
    # ];

    services.kanidm = {
      enableServer = true;
      package = pkgs.unstable.kanidm_1_7; # Use kanidm 1.7 from unstable channel
      
      serverSettings = {
        bindaddress = "0.0.0.0:8443";
        ldapbindaddress = "0.0.0.0:3636";
        origin = "https://idm.xrs444.net";
        domain = "idm.xrs444.net";
        tls_chain = "/var/lib/kanidm/certs/chain.pem";
        tls_key = "/var/lib/kanidm/certs/key.pem";
      };
    };

    # Open firewall ports for kanidm
    networking.firewall = {
      allowedTCPPorts = [ 8443 3636 ];
    };

    # Configure Let's Encrypt for idm.xrs444.net
    security.acme.certs."idm.xrs444.net" = {
      domain = "idm.xrs444.net";
      extraDomainNames = [];
    };

    # Link the ACME certificates to kanidm's expected location
    systemd.services.kanidm-link-certs = {
      description = "Link ACME certificates for Kanidm";
      after = [ "acme-idm.xrs444.net.service" ];
      wants = [ "acme-idm.xrs444.net.service" ];
      wantedBy = [ "kanidm.service" ];
      before = [ "kanidm.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "kanidm";
        Group = "kanidm";
      };
      
      script = ''
        mkdir -p /var/lib/kanidm/certs
        ln -sf /var/lib/acme/idm.xrs444.net/fullchain.pem /var/lib/kanidm/certs/chain.pem
        ln -sf /var/lib/acme/idm.xrs444.net/key.pem /var/lib/kanidm/certs/key.pem
        chown -R kanidm:kanidm /var/lib/kanidm/certs
      '';
    };
  })

  # NixOS client configuration
  (lib.mkIf (!isDarwin) {
    services.kanidm = {
      enableClient = true;
      package = pkgs.unstable.kanidm_1_7; # Use kanidm 1.7 from unstable
      clientSettings = {
        uri = kanidmServerUri;
        verify_ca = true;
        verify_hostnames = true;
      };
    };
  })
]
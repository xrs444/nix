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
  
  # Only xsvr1 should run provisioning
  isProvisioningHost = hostname == "xsvr1";
  
  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";
  
in
lib.mkMerge [

  # Enable provisioning on xsvr1
  (lib.mkIf isProvisioningHost
    (import ./provision.nix { inherit config hostname lib pkgs; }))

  # Use the provisioning-enabled package for servers
  (lib.mkIf isKanidmServer {
    services.kanidm.package = lib.mkForce pkgs.kanidmProvision;
  })

  # Enable Kanidm server configuration
  (lib.mkIf isKanidmServer {
    services.kanidm = {
      enableServer = true;
      enableClient = false;
      enablePam = false;
      serverSettings = {
        bindaddress = "0.0.0.0:8443";
        ldapbindaddress = "0.0.0.0:3636";
        origin = kanidmServerUri;
        domain = "idm.xrs444.net";
        tls_chain = "/var/lib/acme/idm.xrs444.net/cert.pem";
        tls_key = "/var/lib/acme/idm.xrs444.net/key.pem";
        log_level = "info";
        online_backup = {
          path = "/var/lib/kanidm/backups";
          schedule = "0 2 * * *";
          versions = 7;
        };
      };
    };
    
    # Ensure kanidm can read TLS certificates
    users.users.kanidm.extraGroups = [ "acme" ];
    
    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ 8443 3636 ];
    };
  })

]
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
  
  # xsvr1 is the primary server
  isPrimaryServer = hostname == "xsvr1";
  
  # xsvr2 is the replica server
  isReplicaServer = hostname == "xsvr2";
  
  # Only xsvr1 should run provisioning
  isProvisioningHost = hostname == "xsvr1";
  
  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";
  
in
lib.mkMerge [

  # Import provisioning configuration for xsvr1
  (lib.mkIf isProvisioningHost
    (import ./provision.nix { inherit config hostname lib pkgs; }))

  # Use kanidm_1_7 for xsvr2 (non-provisioning server)
  (lib.mkIf isReplicaServer {
    services.kanidm.package = lib.mkDefault pkgs.kanidm_1_7;
  })

  # Primary server configuration (xsvr1)
  (lib.mkIf isPrimaryServer {
    services.kanidm = {
      enableServer = true;
      enablePam = lib.mkForce true;
      enableClient = true;
      unixSettings = {
        pam_allowed_login_groups = [ "posix_users" ];
      };
      serverSettings = {
        bindaddress = "0.0.0.0:443";
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
        replication = {
          origin = kanidmServerUri;
          bindaddress = "0.0.0.0:8444";
        };
      };
      clientSettings = {
        uri = kanidmServerUri;
      };
    };
    
    # Ensure kanidm starts after ACME certificate generation
      systemd.services.kanidm = {
        after = [ "acme-finished-idm.xrs444.net.target" ];
        wants = [ "acme-finished-idm.xrs444.net.target" ];
      } // lib.optionalAttrs (config ? sops.secrets.kanidm_replication_cert) {
        environment = {
          KANIDM_REPLICATION_CERT_PATH = config.sops.secrets.kanidm_replication_cert.path;
        };
      };
    
    # Ensure kanidm can read TLS certificates
    users.users.kanidm.extraGroups = [ "acme" ];
    
    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ 443 3636 8444 ];  # Added 8444 for replication
    };
  })

  # Replica server configuration (xsvr2)
  (lib.mkIf isReplicaServer {
    sops.secrets.kanidm_replication_cert = {
      sopsFile = ./secrets/kanidm_replication_cert.yaml;
      key = "replication_cert";
      owner = "kanidm";
      group = "kanidm";
      mode = "0400";
    };

    services.kanidm = {
      enableServer = true;
      enablePam = false;
      serverSettings = {
        bindaddress = "0.0.0.0:443";
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
        replication = {
          origin = kanidmServerUri;
          bindaddress = "0.0.0.0:8444";
            manual_cert_path = config.sops.secrets.kanidm_replication_cert.path;
        };
      };
    };
    
    # Ensure kanidm starts after ACME certificate generation
    systemd.services.kanidm = {
      after = [ "acme-finished-idm.xrs444.net.target" ];
      wants = [ "acme-finished-idm.xrs444.net.target" ];
    };
    
    # Ensure kanidm can read TLS certificates
    users.users.kanidm.extraGroups = [ "acme" ];
    
    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ 443 3636 8444 ];  # Added 8444 for replication
    };
  })

]
# Summary: NixOS module for Kanidm identity management service, configures server and replica roles for cluster hosts.
{
  config,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:

let
  # Role-based configuration from flake.nix host definitions
  isPrimaryServer = lib.elem "kanidm-primary" hostRoles;
  isReplicaServer = lib.elem "kanidm-replica" hostRoles;
  isKanidmServer = lib.elem "kanidm-server" hostRoles || isPrimaryServer || isReplicaServer;

  # Only primary should run provisioning
  isProvisioningHost = isPrimaryServer;

  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";

in
{
  imports = lib.optionals isProvisioningHost [ ./provision.nix ];

  # Use overlayed pkgs.kanidm for both servers
  config = lib.mkMerge [
    (lib.mkIf isKanidmServer {
      sops.secrets.kanidm_admin_password = {
        sopsFile = ../../../secrets/idm.yaml;
        key = "admin_password";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      sops.secrets.kanidm_idm_admin_password = {
        sopsFile = ../../../secrets/idm.yaml;
        key = "idm_admin_password";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    })
    (lib.mkIf isReplicaServer {
      services.kanidm.package = lib.mkForce pkgs.kanidm;
    })

    # Primary server configuration (xsvr1)
    (lib.mkIf isPrimaryServer {
      # OAuth2 client secrets for provisioning
      sops.secrets.kanidm_oauth2_nocodb_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_nocodb_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_paperless_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_paperless_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_linkwarden_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_linkwarden_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_longhorn_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_longhorn_secret";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      services.kanidm.package = lib.mkForce pkgs.kanidmWithSecretProvisioning_1_7;
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
      }
      // lib.optionalAttrs (config ? sops.secrets.kanidm_replication_cert) {
        environment = {
          KANIDM_REPLICATION_CERT_PATH = config.sops.secrets.kanidm_replication_cert.path;
        };
      };

      # Ensure kanidm can read TLS certificates
      users.users.kanidm.extraGroups = [ "acme" ];

      # Open firewall ports
      networking.firewall = {
        allowedTCPPorts = [
          443
          3636
          8444
        ]; # Added 8444 for replication
      };
    })

    # Replica server configuration (xsvr2)
    (lib.mkIf isReplicaServer {
      sops.secrets.kanidm_replication_cert = {
        sopsFile = ../../../secrets/kanidm_replication_cert.yaml;
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
        allowedTCPPorts = [
          443
          3636
          8444
        ]; # Added 8444 for replication
      };
    })

  ];
}

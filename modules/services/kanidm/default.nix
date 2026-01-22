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
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_idm_admin_password = {
        sopsFile = ../../../secrets/idm.yaml;
        key = "idm_admin_password";
        owner = "kanidm";
        group = "kanidm";
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
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_paperless_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_paperless_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_linkwarden_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_linkwarden_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_longhorn_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_longhorn_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_traefik_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_traefik_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_mealie_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_mealie_secret";
        owner = "kanidm";
        group = "kanidm";
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
            origin = "repl://idm.xrs444.net:8444";
            bindaddress = "0.0.0.0:8444";
            # Pull from xsvr2 by hostname, partner_cert handles mutual TLS auth
            "repl://xsvr2.xrs444.net:8444" = {
              type = "mutual-pull";
              partner_cert = "MIICAzCCAaigAwIBAgIBATAKBggqhkjOPQQDAjBMMRswGQYDVQQKDBJLYW5pZG0gUmVwbGljYXRpb24xLTArBgNVBAMMJDFmYjkyMjY0LTBmZjctNDliMC05MGFlLWY5MTU5MDkwMzlhZDAeFw0yNjAxMDgxNzU4MjdaFw0zMDAxMDgxNzU4MjdaMEwxGzAZBgNVBAoMEkthbmlkbSBSZXBsaWNhdGlvbjEtMCsGA1UEAwwkMWZiOTIyNjQtMGZmNy00OWIwLTkwYWUtZjkxNTkwOTAzOWFkMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEMsFu0wVzowyIZaytCgPcFJqjh-BDodBEpgfrJtEjo6C4itIJuXYTUmqBWa5zAnpUxlMXn1mz5UXL3oNrI4xC0aN7MHkwDAYDVR0TAQH_BAIwADAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMB0GA1UdDgQWBBTaOaPuXmtLDTJVv--VYBiQr9gHCTAbBgNVHREEFDASghB4c3ZyMi54cnM0NDQubmV0MAoGCCqGSM49BAMCA0kAMEYCIQCvP3s9DfH81b83-nltMaGlW7yXbmr2o8fj0PtcrKhExQIhAOXAQYkNNJCZWE8zVVSKsZxKYnoUdWRAvfZsNpbsLKW8";
              # Do NOT set automatic_refresh on primary
            };
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

      # Add OAuth2 redirect URLs after provisioning
      # kanidm-provision doesn't support redirect URLs, so we add them manually
      systemd.services.kanidm-oauth2-redirect-urls = {
        description = "Add OAuth2 redirect URLs to Kanidm clients";
        after = [ "kanidm.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for kanidm to be fully up
          sleep 5

          # Login as idm_admin
          export KANIDM_PASSWORD=$(cat /run/secrets/kanidm_idm_admin_password)
          echo "$KANIDM_PASSWORD" | ${pkgs.kanidm}/bin/kanidm login -D idm_admin || true

          # Add redirect URLs for oauth2 clients (using --name to avoid interactive token selection)
          ${pkgs.kanidm}/bin/kanidm system oauth2 add-redirect-url --name idm_admin oauth2_longhorn https://longhorn.xrs444.net/oauth2/callback || true
          ${pkgs.kanidm}/bin/kanidm system oauth2 add-redirect-url --name idm_admin oauth2_traefik https://traefik.xrs444.net/oauth2/callback || true
          ${pkgs.kanidm}/bin/kanidm system oauth2 add-redirect-url --name idm_admin oauth2_linkwarden https://linkwarden.xrs444.net/api/v1/auth/callback/keycloak || true
          ${pkgs.kanidm}/bin/kanidm system oauth2 add-redirect-url --name idm_admin oauth2_paperless https://paperless.xrs444.net/accounts/oidc/kanidm/login/callback/ || true
          ${pkgs.kanidm}/bin/kanidm system oauth2 add-redirect-url --name idm_admin oauth2_mealie https://mealie.xrs444.net/login || true
        '';
      };

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
            origin = "repl://idm.xrs444.net:8444";
            bindaddress = "0.0.0.0:8444";
            # Pull from xsvr1 by hostname, partner_cert handles mutual TLS auth
            "repl://xsvr1.xrs444.net:8444" = {
              type = "mutual-pull";
              partner_cert = "MIICATCCAaigAwIBAgIBATAKBggqhkjOPQQDAjBMMRswGQYDVQQKDBJLYW5pZG0gUmVwbGljYXRpb24xLTArBgNVBAMMJDc4ZDcyMzdmLWY0NjEtNGZjNS04OGM5LWE1YWE3NTZkYThjNzAeFw0yNjAxMDgxNzU3MDlaFw0zMDAxMDgxNzU3MDlaMEwxGzAZBgNVBAoMEkthbmlkbSBSZXBsaWNhdGlvbjEtMCsGA1UEAwwkNzhkNzIzN2YtZjQ2MS00ZmM1LTg4YzktYTVhYTc1NmRhOGM3MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhipxqb9ju7hXOqL_xNvKLbIloXvkuy53wClGXnoY95A0D1nF_QHt7Ml-2Ids3QkHqwsgCdQBb82xFTSMyoObtKN7MHkwDAYDVR0TAQH_BAIwADAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMB0GA1UdDgQWBBTaOaPuXmtLDTJVv--VYBiQr9gHCTAbBgNVHREEFDASghB4c3ZyMS54cnM0NDQubmV0MAoGCCqGSM49BAMCA0cAMEQCIFLvh5dA0GwM8VUNXWIcckmV7GcORVV8K-jhYktWrbxJAiBjCi0FqNVneSytOGW2KbFuDGfP4aVvLNicqKxjV0cBCg";
              automatic_refresh = true;
            };
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

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
      sops.secrets.kanidm_oauth2_netbox_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_netbox_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_immich_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_immich_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_romm_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_romm_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_audiobookshelf_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_audiobookshelf_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_booklore_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "kanidm_oauth2_booklore_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_matrix_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "kanidm_oauth2_matrix_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      sops.secrets.kanidm_oauth2_seatable_secret = {
        sopsFile = ../../../secrets/kanidm_oauth2_secrets.yaml;
        key = "oauth2_seatable_secret";
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };

      services.kanidm.package = lib.mkForce pkgs.kanidmWithSecretProvisioning;
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
      # kanidm-provision doesn't support redirect URLs, so we add them via the REST API.
      # The kanidm CLI requires an interactive TTY for login and cannot be used in systemd.
      systemd.services.kanidm-oauth2-redirect-urls = {
        description = "Add OAuth2 redirect URLs to Kanidm clients";
        after = [
          "kanidm.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # Don't fail activation if this service fails - it will retry on next boot
          SuccessExitStatus = "0 1 6";
        };
        path = [
          pkgs.curl
          pkgs.jq
        ];
        script = ''
          IDM_URL="https://idm.xrs444.net"
          COOKIES=$(mktemp)
          trap "rm -f $COOKIES" EXIT

          # Wait for Kanidm to be fully ready (with retries)
          echo "Waiting for Kanidm to be ready..."
          for i in {1..30}; do
            if curl -sf "$IDM_URL/v1/auth" >/dev/null 2>&1; then
              echo "Kanidm is ready!"
              break
            fi
            echo "Attempt $i/30: Kanidm not ready yet, waiting..."
            sleep 2
          done

          # Authenticate via REST API (kanidm CLI requires interactive TTY)
          echo "Authenticating to Kanidm..."
          PASSWORD=$(cat /run/secrets/kanidm_idm_admin_password)
          curl -s -c "$COOKIES" -X POST "$IDM_URL/v1/auth" \
            -H "Content-Type: application/json" \
            -d '{"step":{"init":"idm_admin"}}' > /dev/null
          curl -s -b "$COOKIES" -c "$COOKIES" -X POST "$IDM_URL/v1/auth" \
            -H "Content-Type: application/json" \
            -d '{"step":{"begin":"password"}}' > /dev/null
          TOKEN=$(curl -s -b "$COOKIES" -c "$COOKIES" -X POST "$IDM_URL/v1/auth" \
            -H "Content-Type: application/json" \
            -d "{\"step\":{\"cred\":{\"password\":\"$PASSWORD\"}}}" \
            | jq -r '.state.success')

          if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
            echo "ERROR: Failed to authenticate to Kanidm" >&2
            exit 1
          fi

          # Add OAuth2 redirect URL to oauth2_rs_origin
          # Kanidm stores both base origins and supplemental redirect URLs in oauth2_rs_origin
          add_redirect() {
            local client="$1"
            local redirect_url="$2"

            # Extract base origin (protocol://domain:port/)
            local base_origin=$(echo "$redirect_url" | sed -E 's|(https?://[^/]+).*|\1/|')

            echo "Adding redirect URL $redirect_url and origin $base_origin to $client"

            # Get current oauth2_rs_origin values
            local current_origins=$(curl -s -H "Authorization: Bearer $TOKEN" "$IDM_URL/v1/oauth2/$client" \
              | jq -r '.attrs.oauth2_rs_origin[]?' 2>/dev/null)

            # Add both the base origin and full redirect URL to oauth2_rs_origin
            # This ensures both the domain root and the callback path are allowed
            local all_origins=$(printf '%s\n' $current_origins "$base_origin" "$redirect_url" | sort -u | jq -R . | jq -s .)

            # Apply to oauth2_rs_origin
            curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
              "$IDM_URL/v1/oauth2/$client" \
              -d "{\"attrs\":{\"oauth2_rs_origin\": $all_origins}}"
          }

          add_redirect oauth2_traefik   "https://traefik.xrs444.net/oauth2/callback"
          add_redirect oauth2_traefik   "https://nocodb.xrs444.net/oauth2/callback"
          add_redirect oauth2_longhorn  "https://longhorn.xrs444.net/oauth2/callback"
          add_redirect oauth2_paperless "https://paperless.xrs444.net/accounts/oidc/kanidm/login/callback/"
          add_redirect oauth2_mealie    "https://mealie.xrs444.net/login"
          add_redirect oauth2_romm      "https://romm.xrs444.net/oauth/callback"
          add_redirect oauth2_immich    "https://immich.xrs444.net/auth/login"
          add_redirect oauth2_immich    "app.immich:///oauth-callback"
          add_redirect oauth2_netbox    "https://netbox.xrs444.net/oauth/complete/oidc/"
          add_redirect oauth2_linkwarden "https://linkwarden.xrs444.net/api/v1/auth/callback/keycloak"
          add_redirect oauth2_audiobookshelf "https://audiobookshelf.xrs444.net/audiobookshelf/auth/openid/callback"
          add_redirect oauth2_audiobookshelf "https://audiobookshelf.xrs444.net/auth/openid/mobile-redirect"
          add_redirect oauth2_booklore "https://booklore.xrs444.net/oauth2-callback"
          add_redirect oauth2_booklore "https://booklore.xrs444.net/login/oauth2/code/kanidm"
          add_redirect oauth2_matrix "https://matrix.xrs444.net/_synapse/client/oidc/callback"
        '';
      };

      # Restart the OAuth2 redirect URLs service on every activation
      # This ensures redirect URLs are re-applied after nixos-rebuild switch
      system.activationScripts.kanidm-oauth2-redirect-urls = {
        text = ''
          if systemctl is-active kanidm.service >/dev/null 2>&1; then
            echo "Restarting kanidm-oauth2-redirect-urls service to re-apply OAuth2 redirect URLs..."
            systemctl restart kanidm-oauth2-redirect-urls.service || true
          fi
        '';
        deps = [ ];
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

# Summary: Kanidm provision module for NixOS, manages group and password provisioning for identity management.
{
  services.kanidm.provision = {
    enable = true;
    adminPasswordFile = "/run/secrets/kanidm_admin_password";
    idmAdminPasswordFile = "/run/secrets/kanidm_idm_admin_password";
    groups = {
      # User groups
      "admins" = { };
      "users" = { };
      # Application access groups
      "seatable-admin" = {
        members = [ "admins" ];
      };
      "paperless" = {
        members = [ "users" ];
      };
      "paperless-admin" = {
        members = [ "admins" ];
      };
      "linkwarden" = {
        members = [ "users" ];
      };
      "linkwarden-admin" = {
        members = [ "admins" ];
      };
      "longhorn-admin" = {
        members = [ "admins" ];
      };
      "lubelogger" = {
        members = [ "users" ];
      };
      "lubelogger-admin" = {
        members = [ "admins" ];
      };
      "mealie" = {
        members = [ "users" ];
      };
      "mealie-admin" = {
        members = [ "admins" ];
      };
      "netbox" = {
        members = [ "users" ];
      };
      "netbox-admin" = {
        members = [ "admins" ];
      };
      "immich" = {
        members = [ "users" ];
      };
      "immich-admin" = {
        members = [ "admins" ];
      };
      "romm" = {
        members = [ "users" ];
      };
      "romm-admin" = {
        members = [ "admins" ];
      };
      "audiobookshelf" = {
        members = [ "users" ];
      };
      "audiobookshelf-admin" = {
        members = [ "admins" ];
      };
      "booklore" = {
        members = [ "users" ];
      };
      "booklore-admin" = {
        members = [ "admins" ];
      };
      "manyfold" = {
        members = [ "users" ];
      };
      "manyfold-admin" = {
        members = [ "admins" ];
      };
      "matrix" = {
        members = [ "users" ];
      };
      "matrix-admin" = {
        members = [ "admins" ];
      };
      "termix" = {
        members = [ "users" ];
      };
      "termix-admin" = {
        members = [ "admins" ];
      };
      "warpgate" = {
        members = [ "users" ];
      };
      "warpgate-admin" = {
        members = [ "admins" ];
      };
      # POSIX login gate — users in this group can log in to Linux hosts via Kanidm PAM.
      # xsvr1's pam_allowed_login_groups references this group.
      "posix_users" = {
        members = [ "xrs444" "samantha" "rowan" "greyson" ];
      };
      # Host access groups
      "xlt1-t" = { };
      "xlt1-t-admin" = { };
      "xlt2-s" = { };
      "xlt2-s-admin" = { };
      "xdt2-g" = { };
      "xdt2-g-admin" = { };
      "xdt3-r" = { };
      "xdt3-r-admin" = { };
      "xcomm1" = { };
      "xcomm1-admin" = { };
      "xdash1-admin" = { };
      "xhac-radio-admin" = { };
    };
    systems = {
      oauth2 = {
        "oauth2_seatable" = {
          displayName = "Seatable";
          originUrl = "https://seatable.xrs444.net";
          originLanding = "https://seatable.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_seatable_secret";
          scopeMaps = {
            "seatable-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_paperless" = {
          displayName = "Paperless-ngx";
          originUrl = "https://paperless.xrs444.net";
          originLanding = "https://paperless.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_paperless_secret";
          scopeMaps = {
            "paperless" = [
              "openid"
              "profile"
              "email"
            ];
            "paperless-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_linkwarden" = {
          displayName = "Linkwarden";
          originUrl = "https://linkwarden.xrs444.net";
          originLanding = "https://linkwarden.xrs444.net";
          allowInsecureClientDisablePkce = true;
          enableLegacyCrypto = true; # Required for NextAuth compatibility (RS256 instead of ES256)
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_linkwarden_secret";
          scopeMaps = {
            "linkwarden" = [
              "openid"
              "profile"
              "email"
            ];
            "linkwarden-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_longhorn" = {
          displayName = "Longhorn UI";
          originUrl = "https://longhorn.xrs444.net";
          originLanding = "https://longhorn.xrs444.net";
          basicSecretFile = "/run/secrets/kanidm_oauth2_longhorn_secret";
          scopeMaps = {
            "longhorn-admin" = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
          };
        };
        "oauth2_traefik" = {
          displayName = "Traefik Dashboard";
          originUrl = "https://traefik.xrs444.net";
          originLanding = "https://traefik.xrs444.net";
          basicSecretFile = "/run/secrets/kanidm_oauth2_traefik_secret";
          scopeMaps = {
            "admins" = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
          };
        };
        "oauth2_mealie" = {
          displayName = "Mealie";
          originUrl = "https://mealie.xrs444.net";
          originLanding = "https://mealie.xrs444.net";
          allowInsecureClientDisablePkce = true;
          enableLegacyCrypto = true; # Required for Mealie's OIDC implementation
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_mealie_secret";
          scopeMaps = {
            "mealie" = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            "mealie-admin" = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
          };
        };
        "oauth2_netbox" = {
          displayName = "NetBox";
          originUrl = "https://netbox.xrs444.net";
          originLanding = "https://netbox.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_netbox_secret";
          scopeMaps = {
            "netbox" = [
              "openid"
              "profile"
              "email"
            ];
            "netbox-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_immich" = {
          displayName = "Immich Photo Management";
          originUrl = "https://immich.xrs444.net";
          originLanding = "https://immich.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_immich_secret";
          scopeMaps = {
            "immich" = [
              "openid"
              "profile"
              "email"
            ];
            "immich-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_romm" = {
          displayName = "ROMM ROM Manager";
          originUrl = "https://romm.xrs444.net/api/oauth/openid";
          originLanding = "https://romm.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_romm_secret";
          scopeMaps = {
            "romm" = [
              "openid"
              "profile"
              "email"
            ];
            "romm-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_audiobookshelf" = {
          displayName = "Audiobookshelf";
          originUrl = "https://audiobookshelf.xrs444.net";
          originLanding = "https://audiobookshelf.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_audiobookshelf_secret";
          scopeMaps = {
            "audiobookshelf" = [
              "openid"
              "profile"
              "email"
            ];
            "audiobookshelf-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_booklore" = {
          displayName = "Booklore";
          originUrl = "https://booklore.xrs444.net";
          originLanding = "https://booklore.xrs444.net";
          public = true; # BookLore is a public client (PKCE only, no client secret)
          preferShortUsername = true;
          scopeMaps = {
            "booklore" = [
              "openid"
              "profile"
              "email"
              "groups"
              "offline_access"
            ];
            "booklore-admin" = [
              "openid"
              "profile"
              "email"
              "groups"
              "offline_access"
            ];
          };
        };
        "oauth2_matrix" = {
          displayName = "Matrix (Synapse)";
          originUrl = "https://matrix.xrs444.net";
          originLanding = "https://element.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_matrix_secret";
          scopeMaps = {
            "matrix" = [
              "openid"
              "profile"
              "email"
            ];
            "matrix-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_termix" = {
          displayName = "Termix Server Management";
          originUrl = "https://termix.xrs444.net";
          originLanding = "https://termix.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_termix_secret";
          scopeMaps = {
            "termix" = [
              "openid"
              "profile"
              "email"
            ];
            "termix-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_manyfold" = {
          displayName = "Manyfold";
          originUrl = "https://manyfold.xrs444.net";
          originLanding = "https://manyfold.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_manyfold_secret";
          scopeMaps = {
            "manyfold" = [
              "openid"
              "profile"
              "email"
            ];
            "manyfold-admin" = [
              "openid"
              "profile"
              "email"
            ];
          };
        };
        "oauth2_warpgate" = {
          displayName = "Warpgate Bastion";
          originUrl = "https://warpgate.xrs444.net";
          originLanding = "https://warpgate.xrs444.net";
          allowInsecureClientDisablePkce = true;
          preferShortUsername = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_warpgate_secret";
          scopeMaps = {
            "warpgate" = [
              "openid"
              "email"
            ];
            "warpgate-admin" = [
              "openid"
              "email"
            ];
          };
        };
      };
    };
    persons = {
      "xrs444" = {
        displayName = "xrs444";
        legalName = "xrs444";
        mailAddresses = [ "xrs444@xrs444.net" ];
        groups = [
          "admins"
          "posix_users"
        ];
      };
      "samantha" = {
        displayName = "Samantha";
        legalName = "Samantha";
        mailAddresses = [ "samantha@xrs444.net" ];
        groups = [
          "admins"
          "posix_users"
        ];
      };
      "rowan" = {
        displayName = "Rowan";
        legalName = "Rowan";
        mailAddresses = [ "rowan@xrs444.net" ];
        groups = [
          "users"
          "posix_users"
        ];
      };
      "greyson" = {
        displayName = "Greyson";
        legalName = "Greyson";
        mailAddresses = [ "greyson@xrs444.net" ];
        groups = [
          "users"
          "posix_users"
        ];
      };
    };
  };
}

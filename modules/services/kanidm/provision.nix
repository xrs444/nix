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
      "nocodb" = {
        members = [ "users" ];
      };
      "nocodb-admin" = {
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
        "oauth2_nocodb" = {
          displayName = "NocoDB";
          originUrl = "https://nocodb.xrs444.net";
          originLanding = "https://nocodb.xrs444.net";
          allowInsecureClientDisablePkce = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_nocodb_secret";
          scopeMaps = {
            "nocodb" = [
              "openid"
              "profile"
              "email"
            ];
            "nocodb-admin" = [
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
      };
    };
    persons = {
      "xrs444" = {
        displayName = "xrs444";
        legalName = "xrs444";
        mailAddresses = [ "xrs444@xrs444.net" ];
        groups = [
          "admins"
        ];
      };
      "samantha" = {
        displayName = "Samantha";
        legalName = "Samantha";
        mailAddresses = [ "samantha@xrs444.net" ];
        groups = [
          "admins"
        ];
      };
      "rowan" = {
        displayName = "Rowan";
        legalName = "Rowan";
        mailAddresses = [ "rowan@xrs444.net" ];
        groups = [
          "users"
        ];
      };
      "greyson" = {
        displayName = "Greyson";
        legalName = "Greyson";
        mailAddresses = [ "greyson@xrs444.net" ];
        groups = [
          "users"
        ];
      };
    };
  };
}

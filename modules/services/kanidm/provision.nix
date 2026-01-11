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
          originUrl = "https://longhorn.xrs444.net/oauth2/callback";
          originLanding = "https://longhorn.xrs444.net";
          allowInsecureClientDisablePkce = true;
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

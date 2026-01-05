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
      "x_longhorn-admin" = {
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
      "xdt1-t" = { };
      "xdt1-t-admin" = { };
    };
    systems = {
      oauth2 = {
        "oauth2_nocodb" = {
          displayName = "NocoDB";
          originUrl = "https://nocodb.xrs444.net";
          originLanding = "https://nocodb.xrs444.net";
          allowInsecureClientDisablePkce = true;
          basicSecretFile = "/run/secrets/kanidm_oauth2_nocodb_secret";
        };
        "oauth2_paperless" = {
          displayName = "Paperless-ngx";
          originUrl = "https://paperless.xrs444.net";
          originLanding = "https://paperless.xrs444.net";
          basicSecretFile = "/run/secrets/kanidm_oauth2_paperless_secret";
        };
        "oauth2_linkwarden" = {
          displayName = "Linkwarden";
          originUrl = "https://linkwarden.xrs444.net";
          originLanding = "https://linkwarden.xrs444.net";
          basicSecretFile = "/run/secrets/kanidm_oauth2_linkwarden_secret";
        };
        "oauth2_longhorn" = {
          displayName = "Longhorn UI";
          originUrl = "https://longhorn.xrs444.net";
          originLanding = "https://longhorn.xrs444.net";
          basicSecretFile = "/run/secrets/kanidm_oauth2_longhorn_secret";
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

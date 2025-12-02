{
  services.kanidm.provision = {
    enable = true;
    adminPasswordFile = "/run/secrets/kanidm_admin_password";
    idmAdminPasswordFile = "/run/secrets/kanidm_idm_admin_password";
    groups = {
      "lubelogger" = { };
      "lubelogger-admin" = { };
      "xlt1-t" = { };
      "xlt1-t-admin" = { };
      "xlt2-s" = { };
      "xlt2-s-admin" = { };
      "xdt1-t" = { };
      "xdt1-t-admin" = { };
    };
    #    systems = {
    #      oauth2 = {
    #        "craftycontroller" = {
    #          displayName = "CraftyController";
    #          originUrl = "https://crafty.xrs444.net";
    #          scopeMaps = {
    #            openid = [ ];
    #            email = [ ];
    #            profile = [ ];
    #          };
    #        };
    #        "longhorn-oauth2" = {
    #          displayName = "Longhorn UI";
    #          originUrl = "https://longhorn.xrs444.net";
    #          scopeMaps = {
    #            openid = [ ];
    #            email = [ ];
    #            profile = [ ];
    #          };
    #        };
    #      };
    #    };
    persons = {
      "xrs444" = {
        displayName = "xrs444";
        legalName = "xrs444";
        mailAddresses = [ "xrs444@xrs444.net" ];
      };
    };
  };
}

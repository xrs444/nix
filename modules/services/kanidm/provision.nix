{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  # Only xsvr1 should handle provisioning to avoid conflicts
  isProvisioningServer = hostname == "xsvr1";
  
  kanidmServerUri = "https://idm.xrs444.net";
in

lib.mkIf isProvisioningServer {
  
  # SOPS secrets for Kanidm admin password
  sops.secrets."admin_password" = {
    sopsFile = ../../../secrets/idm.yaml;
    owner = "kanidm";
    group = "kanidm";
    mode = "0400";
  };
  
  services.kanidm = {
    provision = {
      enable = true;
      
      # Admin account configuration using SOPS secret
      adminPasswordFile = config.sops.secrets."admin_password".path;
      
      # Create groups
      groups = {
        "lubelogger" = {};
        "lubelogger-admin" = {};
      };      
      # Create persons/users
      persons = {
        "xrs444" = {
          displayName = "xrs444";
          legalName = "xrs444";
          mailAddresses = [ "xrs444@xrs444.net" ];
        };
      };
    };
  };
}
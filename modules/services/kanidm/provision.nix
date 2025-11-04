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

  # Add kanidm-provision CLI tool for xsvr1
  environment.systemPackages = with pkgs; [
    kanidm-provision  # Separate CLI package from overlay
  ];
  
  services.kanidm = {
    # Use the secret provisioning package for xsvr1
    package = lib.mkForce pkgs.kanidmWithSecretProvisioning_1_7;
    
    provision = {
      enable = true;
      # Admin account configuration using SOPS secret
      adminPasswordFile = config.sops.secrets."admin_password".path;
      
      # Create groups
      groups = {
        # Apps
        "lubelogger" = {};
        "lubelogger-admin" = {};
        # Client Access
        "xlt1-t" = {};
        "xlt1-t-admin" = {};
        "xlt2-s" = {};
        "xlt2-s-admin" = {};
        "xdt1-t" = {};
        "xdt1-t-admin" ={};
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
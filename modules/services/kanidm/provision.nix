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
  
  services.kanidm = {
    provision = {
      enable = true;
      
      # Admin account configuration
      adminPasswordFile = "/var/lib/kanidm/admin-password";
      
      # Create groups
      groups = {
        "lubelogger" = {
          description = "can access lubelogger";;
        };
        "lubelogger-admin" = {
          description = "can administrate lubelogger";;
        };
      };      
      # Create persons/users
      persons = {
        "xrs444" = {
          displayName = "xrs444";
          legalName = "xrs444";
          mailPrimary = "xrs444@xrs444.net";
        };

      };
      
      # Create accounts linked to persons
      accounts = {
        "thomas" = {
          person = "thomas";
          description = "Thomas user account";
          groups = [ "wheel" ];
        };
      };
    };
  };
  
  # Ensure admin password file exists with proper permissions
  systemd.services.kanidm-admin-setup = {
    description = "Setup Kanidm admin password";
    wantedBy = [ "multi-user.target" ];
    after = [ "kanidm.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "kanidm";
      Group = "kanidm";
    };
    
    script = ''
      if [ ! -f /var/lib/kanidm/admin-password ]; then
        echo "Please create /var/lib/kanidm/admin-password with the admin password"
        echo "You can generate one with: openssl rand -base64 32 > /var/lib/kanidm/admin-password"
        echo "Then set proper permissions: chown kanidm:kanidm /var/lib/kanidm/admin-password && chmod 600 /var/lib/kanidm/admin-password"
      fi
    '';
  };
}
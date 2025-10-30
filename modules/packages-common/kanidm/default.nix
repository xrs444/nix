{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  # External kanidm server configuration
  kanidmServerUri = "https://idm.xrs444.net";
  
  # Define which kanidm users should have admin privileges (wheel group)
  kanidmAdminUsers = [
    "xrs444"
    "thomas-local"
  ];
  
  # Define which kanidm users should have build privileges
  kanidmBuildUsers = [
    "xrs444"
    "samantha"
    "greyson"
    "rowan"
  ];
  
  # Hosts that should NOT use kanidm (if you need to exclude any)
  excludeHosts = [
    # Add hostnames here if you want to exclude them from kanidm
  ];
  
  # Enable kanidm unless explicitly excluded
  enableKanidm = !(lib.elem hostname excludeHosts);
  
  # Detect if we're on Darwin
  isDarwin = lib.hasInfix "darwin" platform;
in
{
  config = lib.mkIf enableKanidm (lib.mkMerge [
    # Common configuration for both NixOS and Darwin
    {
      # Add kanidm client package to system packages
      environment.systemPackages = [ pkgs.kanidm ];
    }
    
    # NixOS-specific configuration
    (lib.mkIf (!isDarwin) {
      # Kanidm Client Configuration (for external server)
      services.kanidm = {
        enableClient = true;
        clientSettings = {
          uri = kanidmServerUri;
          verify_ca = true;
          verify_hostnames = true;
        };
      };

      # Enable PAM integration for SSH authentication
      security.pam.services.sshd.kanidmSupport = true;
      
      # Enable kanidm for sudo authentication
      security.pam.services.sudo.kanidmSupport = true;
      
      # Enable kanidm for login authentication
      security.pam.services.login.kanidmSupport = true;
      
      # Configure NSS to use kanidm for user lookups
      system.nssModules = [ pkgs.kanidm ];
      system.nssDatabases.passwd = [ "files" "kanidm" ];
      system.nssDatabases.group = [ "files" "kanidm" ];
      
      # Configure automatic home directory creation for kanidm users
      security.pam.services.sshd.makeHomeDir = true;
      security.pam.services.login.makeHomeDir = true;
      
      # Configure sudo rules for kanidm users - always require password
      security.sudo.extraRules = [
        {
          users = kanidmAdminUsers;
          commands = [
            {
              command = "ALL";
              options = [ "PASSWD" ];
            }
          ];
        }
        {
          users = kanidmBuildUsers;
          commands = [
            {
              command = "ALL";
              options = [ "PASSWD" ];
            }
          ];
        }
      ];
      
      # Ensure kanidm admin users are in wheel group for system administration
      users.groups.wheel.members = kanidmAdminUsers;
      
      # Configure SSH to allow kanidm users
      services.openssh = {
        settings = {
          # Allow kanidm users to login via SSH
          AllowUsers = kanidmAdminUsers ++ kanidmBuildUsers ++ [ "builder" "thomas-local" ];
          # Enable public key authentication alongside kanidm
          PubkeyAuthentication = true;
          # Allow password authentication for kanidm users
          PasswordAuthentication = true;
        };
      };
    })
    
    # Darwin-specific configuration
    (lib.mkIf isDarwin {
      # Note: kanidm service integration is more limited on Darwin
      # We can provide the client tools and basic configuration
      
      # Create kanidm client configuration directory and file
      environment.etc."kanidm/config".text = ''
        uri = "${kanidmServerUri}"
        verify_ca = true
        verify_hostnames = true
      '';
      
      # Configure SSH to allow kanidm users (Darwin uses different SSH config)
      programs.ssh.extraConfig = ''
        # Allow kanidm authenticated users
        # Note: Full PAM integration requires additional manual setup on macOS
      '';
      
      # Note: Darwin users will need to:
      # 1. Use 'kanidm login' to authenticate
      # 2. Manually configure SSH keys through kanidm
      # 3. PAM integration is limited compared to NixOS
    })
  ]);
}
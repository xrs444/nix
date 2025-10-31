{ config, lib, pkgs, username, ... }:
{
  users.users.${username} = lib.mkMerge [
    {
      isNormalUser = true;
      description = "${username} user";
      extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
      ];
    }
    # Set initial password for thomas-local specifically
    (lib.mkIf (username == "thomas-local") {
      initialPassword = "changeme"; # Change this on first login
      ignoreShellProgramCheck = true;
      # Force local user creation
      isSystemUser = false;
      createHome = true;
    })
  ];

  # Configure Kanidm to ignore thomas-local
  services.kanidm = lib.mkIf (username == "thomas-local") {
    clientSettings = {
      # Add thomas-local to local users that bypass Kanidm
      pam_allowed_login_groups = [ "wheel" ];
    };
  };

  # Simpler PAM configuration that doesn't interfere with Kanidm
  security.pam.services = lib.mkIf (username == "thomas-local") {
    # Configure PAM to check local users first
    sshd.text = lib.mkAfter ''
      # Fallback to local authentication
      auth sufficient pam_localuser.so
      account sufficient pam_localuser.so
    '';
    
    sudo.text = lib.mkAfter ''
      # Fallback to local authentication for sudo
      auth sufficient pam_localuser.so
      account sufficient pam_localuser.so
    '';
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true;

  # Enable SSH service
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
  };
}
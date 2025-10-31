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
    })
  ];

  # Configure PAM to completely bypass Kanidm for thomas-local
  security.pam.services = lib.mkIf (username == "thomas-local") {
    sshd.text = lib.mkBefore ''
      # Complete bypass for thomas-local user
      auth [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so nullok
      auth required pam_deny.so
      
      account [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      account sufficient pam_unix.so
      account required pam_deny.so
      
      session [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
      session optional pam_systemd.so
    '';
    
    sudo.text = lib.mkBefore ''
      # Complete bypass for thomas-local user in sudo
      auth [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so nullok
      auth required pam_deny.so
      
      account [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      account sufficient pam_unix.so
      account required pam_deny.so
      
      session [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
      session optional pam_systemd.so
    '';
    
    login.text = lib.mkBefore ''
      # Complete bypass for thomas-local user in login
      auth [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so nullok
      auth required pam_deny.so
      
      account [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      account sufficient pam_unix.so
      account required pam_deny.so
      
      session [success=2 default=ignore] pam_succeed_if.so user = thomas-local
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
      session optional pam_systemd.so
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
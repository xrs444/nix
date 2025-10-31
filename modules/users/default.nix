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

  # Configure PAM to bypass Kanidm for thomas-local but preserve group functionality
  security.pam.services = lib.mkIf (username == "thomas-local") {
    sshd.text = lib.mkBefore ''
      # Bypass Kanidm for thomas-local user
      auth [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so
      account [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      account sufficient pam_unix.so
      session [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      session sufficient pam_unix.so
    '';
    
    sudo.text = lib.mkBefore ''
      # Bypass Kanidm for thomas-local user in sudo
      auth [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so
      account [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      account sufficient pam_unix.so
      session [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      session sufficient pam_unix.so
    '';
    
    su.text = lib.mkBefore ''
      # Bypass Kanidm for thomas-local user in su
      auth [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so
      account [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      account sufficient pam_unix.so
      session [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      session sufficient pam_unix.so
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
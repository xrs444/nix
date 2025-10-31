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
    sshd.text = lib.mkForce ''
      # auth
      auth required pam_env.so
      auth sufficient pam_unix.so nullok
      auth required pam_deny.so
      
      # account
      account sufficient pam_unix.so
      
      # session
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
      session required pam_loginuid.so
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
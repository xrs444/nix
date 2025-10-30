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
      # Force local authentication for this user
      ignoreShellProgramCheck = true;
    })
  ];

  # Configure PAM to try local auth first for thomas-local
  security.pam.services = lib.mkIf (username == "thomas-local") {
    login.text = lib.mkBefore ''
      # Try local authentication first for thomas-local
      auth sufficient pam_unix.so
    '';
    su.text = lib.mkBefore ''
      # Try local authentication first for thomas-local  
      auth sufficient pam_unix.so
    '';
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true;
}
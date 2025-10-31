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

  # Configure PAM to allow local authentication for thomas-local
  security.pam.services = lib.mkIf (username == "thomas-local") {
    sshd.text = lib.mkBefore ''
      # Allow local authentication for thomas-local
      auth [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so
    '';
    login.text = lib.mkBefore ''
      # Allow local authentication for thomas-local
      auth [success=1 default=ignore] pam_succeed_if.so user = thomas-local
      auth sufficient pam_unix.so
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
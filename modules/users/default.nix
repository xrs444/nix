{ config, lib, pkgs, username, ... }:
{
  users.users.${username} = lib.mkMerge [
    {
      isNormalUser = true;
      description = "${username} user";
      extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
      shell = "/run/current-system/sw/bin/bash";  # Use explicit path
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
      ];
    }
    # Set initial password for thomas-local specifically
    (lib.mkIf (username == "thomas-local") {
      initialPassword = "changeme"; # Change this on first login
    })
  ];

  # Completely disable Kanidm for thomas-local systems
  services.kanidm = lib.mkIf (username == "thomas-local") {
    enablePam = false;
    enableClient = false;
  };

  # Override PAM configuration for thomas-local to use standard pam_unix
  security.pam.services = lib.mkIf (username == "thomas-local") {
    sshd = {
      unixAuth = true;
      pamMount = false;
    };
    login = {
      unixAuth = true;
      pamMount = false;
    };
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

  # Ensure bash is available and properly configured
  environment.systemPackages = with pkgs; [
    bash
  ];

  # Add shells to /etc/shells
  environment.shells = with pkgs; [ bash ];

  # Set default shell for new users
  users.defaultUserShell = pkgs.bash;

  # Ensure proper session management
  security.pam.loginLimits = lib.mkIf (username == "thomas-local") [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
  ];
}
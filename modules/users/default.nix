{ config, lib, pkgs, username, ... }:
{
  users.users.${username} = lib.mkMerge [
    {
      isNormalUser = true;
      description = "${username} user";
      extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
      shell = pkgs.bashInteractive;  # Use bashInteractive for better session support
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
      ];
    }
    # Set initial password for thomas-local specifically
    (lib.mkIf (username == "thomas-local") {
      initialPassword = "changeme"; # Change this on first login
      createHome = true;
      home = "/home/${username}";
    })
  ];

  # Disable Kanidm PAM completely when using local authentication
  services.kanidm = lib.mkIf (username == "thomas-local") {
    enablePam = false;  # Changed from true to false
  };

  # Ensure standard PAM configuration for local authentication
  security.pam.services = lib.mkIf (username == "thomas-local") {
    sshd = {
      unixAuth = true;
      # Remove custom PAM text to use standard configuration
    };
    login = {
      unixAuth = true;
      # Remove custom PAM text to use standard configuration
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
    bashInteractive
  ];

  # Add shells to /etc/shells
  environment.shells = with pkgs; [ bashInteractive ];

  # Set default shell for new users
  users.defaultUserShell = pkgs.bashInteractive;

  # Ensure proper session management directories exist
  systemd.tmpfiles.rules = lib.mkIf (username == "thomas-local") [
    "d /run/user 0755 root root -"
    "d /var/lib/systemd/linger 0755 root root -"
  ];

  # Enable lingering for the local user to help with session management
  systemd.user.services."user-session-${username}" = lib.mkIf (username == "thomas-local") {
    enable = true;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };
}
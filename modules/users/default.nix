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

  # Configure Kanidm PAM to skip local users
  services.kanidm = lib.mkIf (username == "thomas-local") {
    enablePam = true;
    # Do not set pam_allowed_login_groups here; an empty list denies everyone
  };

  # Override PAM configuration for thomas-local to handle local users properly
  security.pam.services = lib.mkIf (username == "thomas-local") {
    sshd = {
      unixAuth = true;
      pamMount = false;
      text = lib.mkBefore ''
        # Handle local users before Kanidm
        auth    sufficient pam_unix.so nullok likeauth try_first_pass
        account sufficient pam_unix.so
        # Also bypass Kanidm in the session phase for local users
        session sufficient pam_unix.so
      '';
    };
    login = {
      unixAuth = true;
      pamMount = false;
      text = lib.mkBefore ''
        auth    sufficient pam_unix.so nullok likeauth try_first_pass
        account sufficient pam_unix.so
        session sufficient pam_unix.so
      '';
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
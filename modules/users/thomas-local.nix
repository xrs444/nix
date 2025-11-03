{ config, lib, pkgs, ... }:

{
  users.users."thomas-local" = {
    isNormalUser = true;
    description = "thomas-local user";
    extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
    ];
    initialPassword = "changeme";
    createHome = true;
    home = "/home/thomas-local";
    group = "thomas-local";
  };

  users.groups.thomas-local = {};

  # Disable Kanidm PAM completely when using local authentication
  services.kanidm.enablePam = false;

  # Ensure standard PAM configuration for local authentication
  security.pam.services.sshd.unixAuth = true;
  security.pam.services.login.unixAuth = true;

  # Enable lingering for the local user to help with session management
  systemd.user.services."user-session-thomas-local" = {
    enable = true;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };

  # Ensure proper session management directories exist
  systemd.tmpfiles.rules = [
    "d /run/user 0755 root root -"
    "d /var/lib/systemd/linger 0755 root root -"
  ];
}
{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users."thomas-local" = {
    isNormalUser = true;
    description = "thomas-local user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAqv4pyiFGSFn91VWEQ4o2buVrGxlFUsFakiNcMJysK thomas-local@xrs444.net"
    ];
    initialPassword = "changeme";
    createHome = true;
    home = "/home/thomas-local";
    group = "thomas-local";
  };

  users.groups.thomas-local = { };

  # thomas-local is the break-glass account: its keys and password must keep
  # working even when Kanidm PAM/NSS is enabled on a host, so local unix auth
  # stays first in the PAM stack.
  # (sshd.unixAuth is derived automatically from services.openssh.settings.PasswordAuthentication)
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

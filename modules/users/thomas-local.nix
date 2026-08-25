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
      # The orphaned unlabeled key that used to live here (matching no known
      # private key on the fleet — same pattern as the xrs444 key replaced
      # 2026-08-07) was retired 2026-08-25.
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

  # thomas-local's own private key, deployed into its own home so the
  # account can SSH *out* to other hosts (not just accept inbound
  # connections via the authorizedKeys above). Previously this key was only
  # ever deployed to xrs444's home (modules/users/xrs444.nix) for proxied
  # `ssh thomas-local@host` invocations from an interactive xrs444 session —
  # thomas-local itself had no identity file, so host-to-host hops while
  # actually logged in as thomas-local (e.g. break-glass access on a server
  # where thomas-local, not xrs444, is the home-manager-managed user) fell
  # through to ssh's nonexistent default id_* files and failed. Matches the
  # public half already trusted fleet-wide in authorizedKeys.keys above.
  sops.secrets."thomas-local-ssh-key-self" = {
    sopsFile = ../../secrets/thomas-local-ssh-key.yaml;
    key = "thomas_local_private_key";
    owner = "thomas-local";
    group = "thomas-local";
    mode = "0400";
    path = "/home/thomas-local/.ssh/thomas-local_key";
  };

  # System-wide (not home-manager) client config so this works on every
  # NixOS host regardless of whether thomas-local or xrs444 is the
  # home-manager-managed user there (several servers have
  # enableHomeManager = false entirely — see hosts list in flake.nix).
  # `Match ... user thomas-local` matches on the *invoking* local user (see
  # ssh_config(5)), so this only ever applies when actually running as
  # thomas-local. IdentitiesOnly avoids offering any other identity first —
  # extra failed-auth attempts are what has tripped fail2ban on this fleet
  # before (bug-510/524/527).
  programs.ssh.extraConfig = ''
    Match host *.lan user thomas-local
      IdentityFile /home/thomas-local/.ssh/thomas-local_key
      IdentitiesOnly yes
      StrictHostKeyChecking accept-new
  '';

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

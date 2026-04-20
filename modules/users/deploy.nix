# Summary: Dedicated deploy user for deploy-rs push-based deployments from xsvr1.
{ lib, minimalImage, ... }:
{
  config = lib.mkIf (!minimalImage) {
    users.groups.deploy = { };

    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      home = "/var/lib/deploy";
      createHome = true;
      # Shell required by deploy-rs to run the activate-rs binary
      shell = "/run/current-system/sw/bin/bash";
      openssh.authorizedKeys.keyFiles = [ ../../secrets/deploy_key.pub ];
    };

    # deploy-rs copies the store closure to this host via SSH as the deploy user.
    # The nix-daemon requires the connecting user to be trusted before accepting
    # nix-store --serve --write (ssh-ng://) requests; without this the daemon
    # closes the connection, producing "Bad file descriptor" / "unexpected end-of-file".
    nix.settings.trusted-users = [ "deploy" ];

    # deploy-rs needs two NOPASSWD rules. Use extraConfig (raw sudoers) to allow glob
    # patterns, which security.sudo.extraRules does not support natively.
    #
    # In sudoers, '*' in a command PATH component matches any non-'/' string (one component).
    # In argument positions, '*' matches any string including '/'.
    #
    # Rule 1 — Activation:
    #   deploy-rs runs: sudo /nix/store/HASH-activatable-nixos-system-HOSTNAME-VERSION/activate-rs [args]
    #   The activate-rs binary lives at the root of the activatable system store path.
    #   '*' matches the full single-component store directory name (hash + system name).
    #
    # Rule 2 — Magic rollback confirmation:
    #   deploy-rs confirms by running: sudo rm /tmp/deploy-rs-canary-HASH
    #   where HASH is the nix store hash prefix of the activatable system.
    #   sudo resolves 'rm' to its nix store path; '/nix/store/*/bin/rm' covers any version.
    #   The argument '/tmp/deploy-rs-canary-*' matches the canary file (no '/' in hash suffix).
    security.sudo.extraConfig = ''
      deploy ALL=(root) NOPASSWD: /nix/store/*/activate-rs *
      deploy ALL=(root) NOPASSWD: /nix/store/*/bin/rm /tmp/deploy-rs-canary-*
    '';
  };
}

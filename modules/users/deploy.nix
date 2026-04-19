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

    # deploy-rs activates via a store path ending in -activate-rs; path changes each build.
    # Use extraConfig (raw sudoers) to allow a glob pattern, which security.sudo.extraRules
    # does not support natively.
    #
    # sudo 1.9+ treats '*' as matching only within a single path component (no '/').
    # deploy-rs activate.nixos creates a custom activate-rs script whose store path IS the
    # binary: /nix/store/HASH-nixos-system-HOSTNAME-VERSION-activate-rs (no subdirectory).
    # The pattern must end with *-activate-rs (hyphen, not slash), so '*' matches the hash
    # and system name in one component. Two patterns cover all layouts:
    #   - /nix/store/*-activate-rs *     — store path IS the binary (activate.nixos output)
    #   - /nix/store/*/bin/activate-rs * — binary in bin/ subdir (deploy-rs-0.1.0 package)
    security.sudo.extraConfig = ''
      deploy ALL=(root) NOPASSWD: /nix/store/*-activate-rs *
      deploy ALL=(root) NOPASSWD: /nix/store/*/bin/activate-rs *
    '';
  };
}

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

    # deploy-rs activates via /nix/store/*/activate-rs — path changes with each build.
    # Use extraConfig (raw sudoers) to allow a glob pattern, which security.sudo.extraRules
    # does not support natively.
    #
    # Two patterns are needed because sudo 1.9+ treats '*' as matching only within a single
    # path component (i.e. '*' does not match '/'). deploy-rs uses two different layouts:
    #   - Activation:    /nix/store/HASH-nixos-system-...-activate-rs   (binary = store path itself)
    #   - Confirmation:  /nix/store/HASH-deploy-rs-0.1.0/bin/activate-rs (binary in bin/ subdir)
    # The first rule covers the activation binary; the second covers the confirmation binary.
    security.sudo.extraConfig = ''
      deploy ALL=(root) NOPASSWD: /nix/store/*/activate-rs *
      deploy ALL=(root) NOPASSWD: /nix/store/*/bin/activate-rs *
    '';
  };
}

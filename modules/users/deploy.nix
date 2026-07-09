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

    # deploy-rs activates as root by SSHing in and running exactly two sudo'd commands
    # (confirmed by reading deploy-rs src/deploy.rs + src/bin/activate.rs at the pinned
    # revision): the per-deploy activate-rs binary, which already runs as root and
    # internally execs the real activation script (switch-to-configuration or our
    # extlinux wrapper) without needing a second sudo call; and a separate `rm` of the
    # magic-rollback canary/lock file. The store path changes every deploy, so it's
    # globbed on the hash rather than pinned.
    security.sudo.extraRules = [
      {
        users = [ "deploy" ];
        commands = [
          {
            command = "/nix/store/*/activate-rs *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}

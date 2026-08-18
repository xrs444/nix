# Kanidm PAM/NSS client — imported fleet-wide from modules/users/default.nix,
# but inert until a host sets homeprod.kanidm.enablePamLogin = true.
# Provides:
#   - NSS/PAM login for Kanidm persons (kanidm-unixd), scoped to per-host
#     access groups ("<hostname>" / "<hostname>-admin" by default — populate
#     them in modules/services/kanidm/provision.nix)
#   - SSH public key distribution from Kanidm via sshd AuthorizedKeysCommand
#     (additive to static authorized_keys — thomas-local's break-glass keys
#     in modules/users/thomas-local.nix are unaffected)
# Pre-requisites:
#   - the host's age key must be in .sops.yaml creation_rules (all fleet hosts are)
#   - the person needs a POSIX extension + unix password set in Kanidm
#     (see docs/kanidm-user-migration.md — kanidm-provision cannot do this)
# This module only provides the client/PAM side (no server, no provisioning).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeprod.kanidm;
  hostName = config.networking.hostName;
in
{
  options.homeprod.kanidm = {
    enablePamLogin = lib.mkEnableOption "Kanidm PAM/NSS login (kanidm-unixd) on this host";

    allowedLoginGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        hostName
        "${hostName}-admin"
      ];
      description = ''
        Kanidm groups whose members may log in to this host via PAM.
        Defaults to the per-host access groups declared in provision.nix.
      '';
    };

    distributeSshKeys = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Serve SSH public keys stored on Kanidm persons via sshd's
        AuthorizedKeysCommand (kanidm_ssh_authorizedkeys, answered from
        kanidm-unixd's cache). Static authorized_keys files still apply.
      '';
    };
  };

  config = lib.mkIf cfg.enablePamLogin {
    services.kanidm = {
      client.enable = true;
      unix.enable = true;
      unix.settings = {
        kanidm.pam_allowed_login_groups = cfg.allowedLoginGroups;
        home_prefix = "/home";
        home_attr = "uuid";
        home_alias = "spn";
        use_etc_skel = false;
        uid_attr_map = "spn";
        gid_attr_map = "spn";
      };
    };

    # Create home directories on first login. This nixpkgs pin has no global
    # `security.pam.makeHomeDir.enable` toggle — set it per PAM service that
    # authenticates interactive logins (console/su, SSH, GDM password).
    security.pam.services.login.makeHomeDir = true;
    security.pam.services.sshd.makeHomeDir = lib.mkIf config.services.openssh.enable true;
    security.pam.services.gdm-password.makeHomeDir = lib.mkIf config.services.displayManager.gdm.enable true;

    services.openssh = lib.mkIf cfg.distributeSshKeys {
      # Additive to AuthorizedKeysFile: sshd consults both, so nix-static keys
      # (thomas-local, service accounts) keep working if Kanidm is down.
      authorizedKeysCommand = "${pkgs.kanidm}/bin/kanidm_ssh_authorizedkeys %u";
      authorizedKeysCommandUser = "nobody";
    };
  };
}

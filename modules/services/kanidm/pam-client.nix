# Kanidm PAM/NSS client — import this on any NixOS host that should allow
# Kanidm users to log in via SSH or console.
# Pre-requisite: the host's age key must be added to .sops.yaml creation_rules
# so it can decrypt the idm.yaml secret used by the full kanidm/default.nix.
# This module only provides the client/PAM side (no server, no provisioning).
{ ... }:
{
  services.kanidm = {
    enableClient = true;
    enablePam = true;
    clientSettings.uri = "https://idm.xrs444.net";
    unixSettings = {
      pam_allowed_login_groups = [ "posix_users" ];
      home_prefix = "/home";
      home_attr = "uuid";
      home_alias = "spn";
      use_etc_skel = false;
      uid_attr_map = "spn";
      gid_attr_map = "spn";
    };
  };

  # Create home directories on first login
  security.pam.makeHomeDir.enable = true;
}

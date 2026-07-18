{ pkgs, ... }:

{
  users.users.samantha = {
    isNormalUser = true;
    description = "Samantha";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.bashInteractive;
    initialPassword = "changeme";
    createHome = true;
    home = "/home/samantha";
    group = "samantha";
  };

  users.groups.samantha = { };

  # vja (Vikunja CLI) reads its API token from ~/.config/vja/token.json
  # (raw {"token": "..."} JSON, see vja's Features.md#login). Server URL
  # lives in the non-secret config.rc set via home-manager.
  #
  # Deliberately no custom `path` here — see hosts/darwin/default.nix for
  # why a custom path under ~/.config/vja races with home-manager's
  # unprivileged write of config.rc into the same directory. Left at the
  # default /run/secrets/vikunja-api-token-samantha; home-manager symlinks
  # it into place (see homemanager/users/samantha/default.nix).
  sops.secrets."vikunja-api-token-samantha" = {
    sopsFile = ../../secrets/vikunja-api-tokens.yaml;
    key = "samantha_token_json";
    owner = "samantha";
    group = "samantha";
    mode = "0400";
  };
}

{ pkgs, ... }:

{
  programs.fish.enable = true;

  users.users.xrs444 = {
    isNormalUser = true;
    description = "Thomas Letherby (xrs444)";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
    ];
    initialPassword = "changeme";
    createHome = true;
    home = "/home/xrs444";
    group = "xrs444";
  };

  users.groups.xrs444 = { };

  # Provide thomas-local SSH private key to xrs444 user
  sops.secrets."thomas-local-ssh-key" = {
    sopsFile = ../../secrets/thomas-local-ssh-key.yaml;
    key = "thomas_local_private_key";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
    path = "/home/xrs444/.ssh/thomas-local_key";
  };

  # vja (Vikunja CLI) reads its API token from ~/.config/vja/token.json
  # (raw {"token": "..."} JSON, see vja's Features.md#login). Server URL
  # lives in the non-secret config.rc set via home-manager.
  #
  # Deliberately no custom `path` here — see hosts/darwin/default.nix for
  # why a custom path under ~/.config/vja races with home-manager's
  # unprivileged write of config.rc into the same directory. Left at the
  # default /run/secrets/vikunja-api-token-xrs444; home-manager symlinks it
  # into place (see homemanager/users/xrs444/default.nix).
  sops.secrets."vikunja-api-token-xrs444" = {
    sopsFile = ../../secrets/vikunja-api-tokens.yaml;
    key = "xrs444_token_json";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
  };
}

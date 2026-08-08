{
  pkgs,
  lib,
  hostname ? null,
  ...
}:

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
      # Replaced 2026-08-07: the previous key here had no matching private
      # key anywhere on the fleet (orphaned) — this is xrs444's own dedicated
      # identity, distinct from thomas-local (secrets/xrs444-ssh-key.yaml).
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqg7PhaNdpB69GZOwbXgG8XpoWv1wlLBcx+sqW/D2oO xrs444@homeprod"
    ]
    # BetterTouchTool automation on xlt1-t SSHes in as xrs444 using a
    # dedicated key (~/.ssh/obs-key on the Mac, provisioned in
    # hosts/darwin/default.nix) rather than the shared thomas-local key.
    ++ lib.optionals (hostname == "xdt1-t") [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAW81IrYVjb7wFduYvJFUpCE6ni0GPrOr0LyHmEO9BAU xrs444@xlt1-t.i.xrs444.net.lan"
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

  # xrs444's own dedicated identity — default for plain interactive `ssh
  # <host>.lan` (see homemanager/users/xrs444/default.nix). thomas-local
  # stays reserved for explicit thomas-local@ invocations (automation).
  sops.secrets."xrs444-ssh-key" = {
    sopsFile = ../../secrets/xrs444-ssh-key.yaml;
    key = "xrs444_private_key";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
    path = "/home/xrs444/.ssh/xrs444_key";
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

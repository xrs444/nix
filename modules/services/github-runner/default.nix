# Summary: NixOS module for self-hosted GitHub Actions runner, enabling CI builds on xsvr1.
{
  hostRoles ? [ ],
  config,
  lib,
  pkgs,
  ...
}:
let
  hasRole = lib.elem "github-runner" hostRoles;
in
lib.mkIf hasRole {
  sops.secrets.github_runner_token = {
    sopsFile = ../../../secrets/github-runner-token.yaml;
    key = "github_runner_token";
  };

  services.github-runners.xsvr1-builder = {
    enable = true;
    url = "https://github.com/xrs444/nix";
    tokenFile = config.sops.secrets.github_runner_token.path;
    user = "builder";
    group = "builders";
    workDir = "/zfs/nixcache/builds/github-runner";
    extraLabels = [
      "nixos"
      "x86_64-linux"
      "builder"
    ];
    extraPackages = with pkgs; [
      git
      nix
      curl
      jq
      coreutils
      bash
    ];
    serviceOverrides = {
      # Ensure the runner has access to nix daemon
      SupplementaryGroups = [ "nixbld" ];
    };
  };

  # Ensure the working directory exists
  systemd.tmpfiles.rules = [
    "d /zfs/nixcache/builds/github-runner 0775 builder builders -"
  ];
}

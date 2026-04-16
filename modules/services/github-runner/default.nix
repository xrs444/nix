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

  # Oneshot service that applies the xsvr1 NixOS config from the current checkout.
  # The builder user is granted polkit permission to start it, avoiding sudo entirely.
  systemd.services.nixos-rebuild-ci = {
    description = "Apply NixOS configuration for xsvr1 (CI self-deploy)";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/nixos-rebuild switch --flake /zfs/nixcache/builds/github-runner/nix/nix#xsvr1";
      # Run as root so nixos-rebuild can activate the new system
      User = "root";
    };
  };

  # Allow the builder user to start the CI rebuild service via systemctl.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") === "nixos-rebuild-ci.service" &&
          action.lookup("verb") === "start" &&
          subject.user === "builder") {
        return polkit.Result.YES;
      }
    });
  '';

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
      openssh
    ];
    serviceOverrides = {
      # Ensure the runner has access to nix daemon
      SupplementaryGroups = [ "nixbld" ];
      # Allow writing to the nix binary cache directory
      ReadWritePaths = [ "/zfs/nixcache/cache" ];
      # Auto-restart on failure (default is Restart=no which requires manual intervention)
      Restart = lib.mkForce "on-failure";
      RestartSec = "30s";
    };
  };

  # Ensure the working directory exists
  systemd.tmpfiles.rules = [
    "d /zfs/nixcache/builds/github-runner 0775 builder builders -"
  ];
}

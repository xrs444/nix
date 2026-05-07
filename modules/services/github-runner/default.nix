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
  #
  # Triggered by the path unit below — no polkit or systemctl call from the builder
  # user required. The CI step simply creates the permit token file; systemd watches
  # for it and starts this service automatically.
  #
  # Guard: ExecStartPre consumes the token atomically. Any stale invocation without
  # a token exits immediately without touching the system.
  #
  # NOTE: token path must NOT be in /tmp — the github-runner service has PrivateTmp=true,
  # so the runner's `touch /tmp/...` writes to a private tmpfs invisible to this service.
  systemd.services.nixos-rebuild-ci = {
    description = "Apply NixOS configuration for xsvr1 (CI self-deploy)";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStartPre = "/bin/sh -c 'test -f /zfs/nixcache/builds/github-runner/nixos-rebuild-ci-permitted && rm -f /zfs/nixcache/builds/github-runner/nixos-rebuild-ci-permitted || { echo \"nixos-rebuild-ci: no permit token — refusing to run\"; exit 1; }'";
      ExecStart = "/run/current-system/sw/bin/nixos-rebuild switch --flake /zfs/nixcache/builds/github-runner/nix/nix#xsvr1";
      User = "root";
    };
  };

  # Path unit that watches for the permit token and starts nixos-rebuild-ci.service
  # automatically. The CI step only needs to `touch` the token — no D-Bus/systemctl
  # call from the sandbox-restricted builder user required.
  systemd.paths.nixos-rebuild-ci = {
    description = "Watch for CI nixos-rebuild permit token";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathExists = "/zfs/nixcache/builds/github-runner/nixos-rebuild-ci-permitted";
      Unit = "nixos-rebuild-ci.service";
    };
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
      openssh
    ];
    serviceOverrides = {
      # Ensure the runner has access to nix daemon
      SupplementaryGroups = [ "nixbld" ];
      # Allow writing to the nix binary cache and the runner workDir.
      # NOTE: serviceOverrides.ReadWritePaths replaces the module default (which includes
      # workDir), so both paths must be listed explicitly here.
      ReadWritePaths = [ "/zfs/nixcache/cache" "/zfs/nixcache/builds/github-runner" ];
      # Grant read access to sops secrets (deploy key lives at /run/secrets/deploy_private_key;
      # ProtectHome=true blocks /home/builder/.ssh/ so the key must not live there)
      ReadOnlyPaths = [ "/run/secrets" ];
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

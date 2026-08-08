# Summary: Darwin/macOS host configuration, imports common and platform-specific package modules.
{
  lib,
  platform,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../modules/packages-common/default.nix
    ../../modules/packages-darwin/default.nix
    ../../modules/packages-darwin/brew-packages.nix
    ../../modules/packages-workstation/default.nix
  ];

  # Set system state version
  system.stateVersion = 5;

  # sops-nix on Darwin: no host SSH key to derive an age key from (unlike
  # base-nixos.nix's /etc/ssh/sops-age-key.txt), so decryption uses the
  # user's own personal age key instead. That key must already exist at this
  # path on every Darwin host (it's the same key used for manual `sops -d`
  # via SOPS_AGE_KEY_FILE in home-manager, and is one of the recipients in
  # .sops.yaml as user_xrs444 — not host-specific, so it's shared across
  # xlt1-t and xcog1). Runs via system.activationScripts.postActivation
  # (on darwin-rebuild switch) and a RunAtLoad launchd daemon (on boot).
  sops.age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../../secrets/vikunja-api-tokens.yaml;

  # vja (Vikunja CLI) API token — see homemanager/users/xrs444/default.nix
  # for the non-secret config.rc, and modules/users/xrs444.nix for the
  # equivalent secret on xrs444's NixOS hosts (same key, one token per user
  # shared across all their machines).
  #
  # Deliberately no custom `path` here: sops secrets are placed by root
  # during darwin-rebuild switch, so a custom path under ~/.config/vja
  # forces that directory to be created root-owned. home-manager (running
  # unprivileged, separately) then can't write config.rc into the same
  # directory and its activation aborts partway — which is what silently
  # wiped VS Code's extension symlinks on xlt1-t. Leaving the secret at its
  # default /run/secrets/vikunja-api-token and letting home-manager symlink
  # it in (see homemanager/users/xrs444/default.nix) avoids the race.
  sops.secrets."vikunja-api-token" = {
    key = "${username}_token_json";
    owner = username;
    group = "staff";
    mode = "0400";
  };

  # SSH private keys for ${username}'s ad-hoc admin access, declaratively
  # provisioned to ~/.ssh so they survive a fresh machine / are backed up
  # encrypted in git — mirrors the pattern already used for thomas-local_key
  # on NixOS (modules/users/xrs444.nix). Real files land on disk (not an
  # agent-only vault) so existing ad-hoc `ssh -i ~/.ssh/<key>` commands and
  # scripts keep working unchanged. See homemanager/users/xrs444/default.nix
  # for the matching programs.ssh routing (which key is offered for which
  # host).
  sops.secrets."ssh-thomas-local" = {
    sopsFile = ../../secrets/thomas-local-ssh-key.yaml;
    key = "thomas_local_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/thomas-local_key";
  };

  # xrs444's own dedicated identity — see modules/users/xrs444.nix for the
  # matching NixOS-side secret and authorized_key.
  sops.secrets."ssh-xrs444" = {
    sopsFile = ../../secrets/xrs444-ssh-key.yaml;
    key = "xrs444_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/xrs444_key";
  };

  # Same identity as the fleet's /etc/ssh/id_builder (modules/services/remotebuilds/default.nix)
  # — xcog1/xlt1-t reference this local copy directly in their own nix.buildMachines
  # (they don't import the remotebuilds NixOS module) so it needs its own path here.
  sops.secrets."ssh-builder" = {
    sopsFile = ../../secrets/builder-ssh-key.yaml;
    key = "builder_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/builder_key";
  };

  # Nutanix cluster admin access (xntnx).
  sops.secrets."ssh-ntnx" = {
    sopsFile = ../../secrets/ntnx-ssh-key.yaml;
    key = "ntnx_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/ntnx";
  };

  # Legacy Brocade/FastIron switch admin (xswcore and friends) — RSA key,
  # needs the legacy KexAlgorithms/PubkeyAcceptedKeyTypes carried in ssh
  # config alongside it (see homemanager/users/xrs444/default.nix).
  sops.secrets."ssh-ansible-brocade" = {
    sopsFile = ../../secrets/ansible-brocade-ssh-key.yaml;
    key = "ansible_brocade_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/ansible-brocade_key";
  };

  # opc@vocibuild.xrs444.net — Oracle Cloud's default per-instance admin
  # user, separate from the builder/deploy service identities.
  sops.secrets."ssh-oci" = {
    sopsFile = ../../secrets/oci-ssh-key.yaml;
    key = "oci_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/oci";
  };

  # pi@<firewalla> — Firewalla's fixed default SSH username; not a
  # Nix-managed host so there's no fixed hostname to route on.
  sops.secrets."ssh-pi" = {
    sopsFile = ../../secrets/pi-ssh-key.yaml;
    key = "pi_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/pi";
  };

  # BetterTouchTool automation scripts on xlt1-t use this to reach xdt1-t
  # as xrs444 (see modules/users/xrs444.nix for the matching authorized_key
  # on xdt1-t).
  sops.secrets."ssh-obs" = {
    sopsFile = ../../secrets/obs-ssh-key.yaml;
    key = "obs_private_key";
    owner = username;
    group = "staff";
    mode = "0600";
    path = "/Users/${username}/.ssh/obs-key";
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;

  # DS Nix owns /etc/nix/nix.conf and will overwrite it on updates.
  # User settings go in nix.custom.conf (included via !include in nix.conf).
  # With nix.enable = false, nix-darwin's nix.settings is never written anywhere,
  # so we manage nix.custom.conf directly via environment.etc instead.
  nix.enable = false;
  environment.etc."nix/nix.custom.conf".text = ''
    sandbox = false
    trusted-users = root @admin ${username}
    extra-substituters = http://nixcache.xrs444.net?priority=10
    extra-trusted-public-keys = xsvr1.lan-1:zYWtshSYClLIckawdxzJEuy82yifQX2pbultumrToKI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
    extra-experimental-features = nix-command flakes
    download-buffer-size = 134217728
    builders-use-substitutes = true
  '';

  # Configure nixpkgs
  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";

    # Package overrides
    config.packageOverrides = pkgs: {
      pythonPackagesExtensions = pkgs.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          setproctitle = python-prev.setproctitle.overridePythonAttrs (old: {
            # Skip tests on macOS due to fork-related segfaults in test suite
            # See: https://github.com/dvarrazzo/py-setproctitle/issues/113
            doCheck = false;
          });
          aiohttp = python-prev.aiohttp.overridePythonAttrs (old: {
            # test_base_ctor calls socket.getfqdn() at build time; on this machine
            # it returns the search-domain FQDN (xlt1-t.i.xrs444.net.lan) which
            # doesn't match the short hostname the test expects (xlt1-t.lan)
            doCheck = false;
          });
          inline-snapshot = python-prev.inline-snapshot.overridePythonAttrs (old: {
            # inline-snapshot is a pytest plugin; pytest is a runtime dep but is
            # missing from nixpkgs 25.11 propagatedBuildInputs, causing
            # pythonRuntimeDepsCheckHook to fail. Add it directly.
            doCheck = false;
            propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ python-prev.pytest ];
          });
        })
      ];
    };
  };

  # Garbage collection via LaunchDaemon (since nix.enable = false)
  launchd.daemons.nix-gc = {
    command = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 30d";
    serviceConfig = {
      StartCalendarInterval = [
        {
          Weekday = 0; # Sunday
          Hour = 2;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  # Re-sign critical Nix binaries after every rebuild.
  # Nix fetches binaries from binary caches (including custom ones built on Linux)
  # and may not always complete the macOS ad-hoc signing step. An unsigned or
  # invalidly-signed binary is SIGKILL'd by macOS on Apple Silicon before it runs,
  # which is fatal when the binary is the login shell.
  system.activationScripts.signNixBinaries.text = ''
    echo "Re-signing Nix binaries for macOS..." >&2
    for bin in fish; do
      bin_path=$(readlink -f /run/current-system/sw/bin/$bin 2>/dev/null || true)
      if [ -n "$bin_path" ] && [ -f "$bin_path" ]; then
        /usr/bin/codesign --force --sign - "$bin_path" 2>/dev/null \
          && echo "  signed: $bin_path" >&2 \
          || echo "  WARNING: failed to sign $bin_path" >&2
      fi
    done
  '';
}

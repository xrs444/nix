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
}

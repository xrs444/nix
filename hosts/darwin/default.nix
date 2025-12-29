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

  nix = {
    enable = false;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      trusted-users = [
        "@admin"
        username
      ];
    };
  };

  # Configure nixpkgs
  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";

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

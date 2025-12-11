{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  desktop,
  ...
}:
{
  imports = [
    ../default.nix
  ];

  # Host-specific configuration for xlt1-t (MacBook)
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.primaryUser = "xrs444";

  # macOS-specific settings
  system.defaults = {
    menuExtraClock.Show24Hour = true;
    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 36;
      largesize = 48;
      scroll-to-open = true;
      persistent-apps = [
        "Visual Studio Code.app"
        "Firefox.app"
        "Ghostty.app"
      ];
    };
    controlcenter = {
      BatteryShowPercentage = true;
    };
    finder = {
      AppleShowAllExtensions = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "clmv";
      AppleShowAllFiles = true;
      FXRemoveOldTrashItems = true;
      ShowExternalHardDrivesOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleInterfaceStyle = "Dark";
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
  };

  # Manual PAM configuration for Touch ID (if needed)
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin for Touch ID support
    auth       sufficient     pam_tid.so
  '';

  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix
  '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
  '';

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];
}

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
  # Host-specific configuration for xlt1-t (MacBook)
  
  # Set the hostname
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.primaryUser = "xrs444";
  
  # macOS-specific settings
  system.defaults = {
    
    menuExtraClock.Show24Hour = true;
    # Dock configuration
    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 36;
      largesize = 48;
      scroll-to-open = true;
      persistant-apps = [
        "Finder"
        "Visual Studio Code"
        "Firefox"
        "GhostTTY"
        "VS Code"
      ];
    };

    controlcenter = {
      BatteryShowPercentage = true;
    };

    # Finder configuration
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv"; # Column view
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      AppleShowAllFiles = true;
      FXRemoveOldTrashItems = true;
      ShowExternalHardDrivesOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;

    };
    
    # System UI configuration
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleInterfaceStyle = "Dark";
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
  };

  # When GA:
  #extra-experimental-features = external-builders
  #external-builders = [{"systems":["aarch64-linux","x86_64-linux"],"program":"/usr/local/bin/determinate-nixd","args":["builder"]}]

  # Manual PAM configuration for Touch ID (if needed)
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin for Touch ID support
    auth       sufficient     pam_tid.so
  '';
}
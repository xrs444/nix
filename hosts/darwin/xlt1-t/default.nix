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
    # Dock configuration
    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 36;
    };
    
    # Finder configuration
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv"; # Column view
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    
    # System UI configuration
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
  };
  
  # Manual PAM configuration for Touch ID (if needed)
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin for Touch ID support
    auth       sufficient     pam_tid.so
  '';
}
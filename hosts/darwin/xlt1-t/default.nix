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

    nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation.cores = 4;
      virtualisation.memorySize = 8192;
    };
  };
  
  # Manual PAM configuration for Touch ID (if needed)
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin for Touch ID support
    auth       sufficient     pam_tid.so
  '';
}
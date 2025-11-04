{ pkgs, ... }:

{
  # Homebrew packages that don't have Nix equivalents or work better via Homebrew
  homebrew = {
    enable = true;
    
    # Packages installed via `brew install`
    brews = [
      "anylinuxfs" 
      "sshfs-mac"
    ];
    
    # GUI applications installed via `brew install --cask`
    casks = [
      "handbrake"
    ];
    
    # Mac App Store applications
    masApps = {
      "Bitwarden" = 1352778147;
      "Brother P-touch Editor" = 1453365242;
      "Clean Email" = 1441250616;
      "CrystalFetch" = 6454431289;
      "Duplicate File Finder" = 1032755628;
      "GarageBand" = 682658836;
      "HP" = 1474276998;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Kindle" = 302584613;
      "Microsoft Outlook" = 985367838;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Tailscale" = 1475387142;
      "Telegram" = 747648890;
      "The Unarchiver" = 425424353;
      "UTM" = 1538878817;
      "WireGuard" = 1451685025;
    };
    
    # Automatically update Homebrew and packages
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
  };
}
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
      "amethyst"
      "balenaetcher"
      "bambu-studio"
      "batteryboi"
      "beeper"
      "betterdisplay"
      "elgato-stream-deck"
      "firewalla"
      "ghostty"
      "google-drive"
      "handbrake"
      "headlamp"
      "huiontablet"
      "ice"
      "jabra-direct"
      "jettison"
      "lulu"
      "minecraft"
      "naps2"
      "qmk-toolbox"
      "raspberry-pi-imager"
      "sf-symbols"
      "syncthing"
      "zoom"
    ];
    
    # Mac App Store applications
    masApps = {
      "Bitwarden" = 1352778147;
      "Brother P-touch Editor" = 1453365242;
      "Clean Email" = 1441250616;
      "Cricut Design Space" = 1422528930;
      "CrystalFetch" = 6454431289;
      "Duplicate File Finder" = 1032755628;
      "HP" = 1474276998;
      "Kindle" = 302584613;
      "Microsoft Teams" = 1113153706;
      "Tailscale" = 1475387142;
      "Telegram" = 747648890;
      "TrainerRoad" = 1056599398;
      "UTM" = 1538878817;
      "Windows App" = 1295203466;
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
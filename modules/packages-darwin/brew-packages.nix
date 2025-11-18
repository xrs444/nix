{ pkgs, ... }:

{
  # Homebrew packages that don't have Nix equivalents or work better via Homebrew
  homebrew = {
    enable = true;
    
    # Packages installed via `brew install`
    brews = [
      "helm"
      "lazyssh"
      "ice"
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
      "firefox"
      "ghostty"
      "google-drive"
      "handbrake-app"
#      "headlamp" currently broken
      "jabra-direct"
      "jettison"
      "lulu"
      "minecraft"
      "naps2"
      "postman"
      "qmk-toolbox"
      "raspberry-pi-imager"
      "raycast"
      "sf-symbols"
      "syncthing-app"
      "visual-studio-code"
      "zoom"
      "bettertouchtool"
      "via"
#      "calibre"
#      "vlc"

    ];

    # Mac App Store applications
    masApps = {
      "Bitwarden" = 1352778147;
      "Brother P-touch Editor" = 1453365242;
      "Clean Email" = 1441250616;
      "CrystalFetch" = 6454431289;
      "Duplicate File Finder" = 1032755628;
      "HP" = 1474276998;
      "Kindle" = 302584613;
      "Tailscale" = 1475387142;
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

{ ... }:

{
  # Homebrew packages that don't have Nix equivalents or work better via Homebrew
  homebrew = {
    enable = true;
    # Homebrew taps required for some packages
    taps = [
      "qmk/qmk"
    ];

    # Packages installed via `brew install`
    brews = [
      "helm"
      "lazyssh"
      "ice"
      "mas"
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
      "wezterm"
      "google-drive"
      "handbrake-app"
      { name = "headlamp"; args = { no_quarantine = true; }; }
      "jabra-direct"
      "jettison"
      "kobo"
      "lulu"
      "microsoft-teams"
      "minecraft"
      "naps2"
      "postman"
      "qmk-toolbox"
      "raspberry-pi-imager"
      "raycast"
      "sf-symbols"
      "syncthing-app"
      "zoom"
      "bettertouchtool"
      "via"
      "calibre"
      "vlc"
      "google-chrome"

    ];

    # Mac App Store applications
    masApps = {
      "Bitwarden" = 1352778147;
      "Brother P-touch Editor" = 1453365242;
      "Button Creator" = 1559303865;
      "Clean Email" = 1441250616;
      "CrystalFetch" = 6454431289;
      "Duplicate File Finder" = 1032755628;
      "HP" = 1474276998;
      "Kindle" = 302584613;
      "SerialTools" = 611021963;
      "Tailscale" = 1475387142;
      "Telegram" = 747648890;
      "TickTick" = 966085870;
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

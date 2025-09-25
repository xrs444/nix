{
  lib,
  pkgs,
  username,
  platform,
  ...
}:
let
  installFor = [ "xrs444" ];
in
lib.mkIf (lib.elem username installFor && platform == "aarch64-darwin") {
  environment.systemPackages = with pkgs; [
    # CLI Tools & Development
    age
    ansible
    ansible-lint
    arping
    atuin
    chezmoi
    cilium-cli
    fish
    flux
    git
    go
    helm
    hugo
    kubernetes-helm
    kubectl
    kubeseal
    kustomize
    llvm
    mas
    nmap
    nodejs
    openjdk
    pipx
    rust
    p7zip
    sops
    sshpass
    starship
    tmux
    virtualenv
    yamllint
    yq
    yt-dlp
    
    # GUI Applications
    handbrake
    firefox
    vlc
    bitwarden
    google-chrome
    telegram-desktop
    tailscale
    wireshark
    calibre
    the-unarchiver
    vscode
  ];

  homebrew = {
    casks = [
      # macOS-specific & specialized tools
      "sshfs-mac"
      "alfred"
      "raycast"
      "iterm2" 
      "ghostty"
      "utm"
      "bambu-studio"
      "openscad"
      "cricut-design-space"
      "powershell"
      "huion-firmware-update-tool"
      "huion-tablet"
      "qmk-toolbox"
      "trainerroad"
      "ice-minecraft"
      "porting-kit"
      "zoiper5"
      "duplicate-file-finder"
      "lulu"
      "firewalla"
      "balenaetcher"
      "freefilesync"
      "realtimesync"
      "naps2"
      "batteryBoi"
      "better-display"
      "jettison"
      "amethyst"
      "drivethru-rpg"
      
      # Either way (keeping in homebrew for now)
      "github-desktop"
      "postman"
      "beeper"
      "wireguard-tools"
      "raspberry-pi-imager"
      "clean-email"
      "logi-tune"
      "crystalfetch"
      "headlamp"
      "sf-symbols"
      "windows-app"
      "jitsi-meet"
      "kdeconnect"
    ];
  };
}

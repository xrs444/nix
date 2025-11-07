{ pkgs, ... }:

{
  imports = [
    ../packages-common/kanidm
    ./tailscale
    ./brew-packages.nix
  ];

  # Darwin-specific packages (Nix packages)
  environment.systemPackages = with pkgs; [
    # Development tools
    age
    ansible
    ansible-lint
    git
    go
    hugo
    lua
    nodejs
    openjdk
    rbenv
    ruby
    rust
    
    # Kubernetes & Cloud Native
    cilium-cli
    cmctl
    flux
    helm
    hubble
    kubectl
    kubeseal
    kustomize
    talosctl
    
    # System utilities
    arping
    atuin
    baobab
    chezmoi
    fish
 #   lazyssh
    mas
    nmap
    sops
    starship
    sshpass
    tfswitch
    tmux
    tree
    wget
    yamllint
    yq
    yt-dlp
    
    # Compression & archives
    _7zz
    brotli
    lz4
    lzo
    p7zip
    wimlib
    xz
    zstd
    
    # Multimedia
    lame
#    opus
#    theora
    x264
    
    # Browsers & Communication
    firefox
    thunderbird
    
    # Development Tools
    vscode
    github-desktop
    postman
    
    # Media & Productivity
    vlc
    calibre
    obsidian
    logseq
    
    # Utilities
    iterm2
    raycast
    wireshark
    openscad
    powershell
    
    # Other utilities
    pipx
    virtualenv
  ];
}

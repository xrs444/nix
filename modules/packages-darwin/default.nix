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
    git
    go
    hugo
    lua
    nodejs
    openjdk
    rbenv
    ruby
    
    # Kubernetes & Cloud Native
    cilium-cli
    cmctl
    fluxcd
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
    x264
    
    # Browsers & Communication
    thunderbird
    
    # Utilities
    iterm2
    wireshark
    openscad
    powershell
    
    # Other utilities
    pipx
    virtualenv
  ];
}

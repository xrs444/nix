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
    python313
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
    fish
    lazyssh
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
    xz
    zstd
    
    # Multimedia
    lame
    opus
    theora
    x264
    
    # Other utilities
    pipx
    virtualenv
  ];
}
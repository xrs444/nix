{ pkgs, ... }:

{
  imports = [
    ../packages-common/kanidm
    ./brew-packages.nix
    ./qmk/default.nix
  ];

  # Darwin-specific packages (Nix packages)
  environment.systemPackages = with pkgs; [
    age
    git
    wget
    fish
    lame
    x264
    hugo
    lua
    nodejs
    openjdk
    ruby
    ansible

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
    baobab
    home-manager
    nmap
    sops
    sshpass
    tfswitch
    tree
    yamllint
    yq

    # Compression & archives
    _7zz
    brotli
    lz4
    lzo
    p7zip
    wimlib
    xz
    zstd

    # Utilities
    gitkraken
    iterm2
    wireshark
    openscad
    powershell
    # vscode is managed by home-manager with pkgs.unstable (see homemanager/common/apps/vscode)

    # Other utilities
    pipx
    virtualenv
    ollama
  ];
}

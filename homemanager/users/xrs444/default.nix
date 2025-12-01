{
  pkgs,
  stateVersion,
  username,
  ...
}:
{

  home.stateVersion = stateVersion;
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Thomas Letherby";
      userEmail = "xrs444@xrs444.net";
      ignores = [ ".DS_Store" ];
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "micro";
      };
    };
    fish = {
      enable = true;
      shellAliases = {
        nix-sh = "fish $HOME/.local/bin/nix-sh.fish";
      };
    };
    starship.enable = true;
    go.enable = true;
    rbenv.enable = true;
    atuin.enable = true;
    tmux.enable = true;
    yt-dlp.enable = true;
  };

  # Apps
  imports = [
    ../../common/apps/gitkraken
    ../../common/apps/vscode
    ./shell/git.nix
    ./shell/starship.nix
    ./shell/tmux.nix
  ];

  # Ensure gitkraken and vscode are installed only for xrs444
  # programs.gitkraken.enable = true; # Removed: not a valid Home Manager option
  programs.vscode.enable = true;

  # Install non-standard fonts
  home.packages = with pkgs; [
    gitkraken
    # Nerd Fonts for terminal and coding
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    nerd-fonts.hack
    nerd-fonts.iosevka
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
    direnv
    teams # Microsoft Teams (official client)
    # Flux/Kustomize/CI tools for xrs444
    kustomize
    kubeconform
    yamllint
    pre-commit
    # Add any CLI or GUI apps not supported as Home Manager modules here
    hugo
    lua
    nodejs
    openjdk
    ruby
    ansible
    cilium-cli
    cmctl
    fluxcd
    hubble
    kubectl
    kubeseal
    kustomize
    talosctl
    arping
    baobab
    chezmoi
    nmap
    sops
    sshpass
    tfswitch
    tree
    yamllint
    yq
    _7zz
    brotli
    lz4
    lzo
    p7zip
    wimlib
    xz
    zstd
    thunderbird
    iterm2
    wireshark
    openscad
    powershell
    pipx
    virtualenv
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;

  # Deploy nix-sh.fish selector script to ~/.local/bin
  home.file.".local/bin/nix-sh.fish" = {
    source = builtins.path { path = ./../../../scripts/nix-sh.fish; };
    executable = true;
  };

  # Set default shell preferences
  home.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "firefox";
    SOPS_AGE_KEY_FILE = "/Users/xrs444/.config/sops/age/keys.txt";
    KUBECONFIG = "/Users/xrs444/k8s/config";
    TALOSCONFIG = "Users/xrs444/Repositories/HomeProd/talos/config.yaml";
    PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
  };

  # Enable Catppuccin theme globally
  # catppuccin = {
  #   enable = true;
  #   flavor = "mocha";
  # };

}

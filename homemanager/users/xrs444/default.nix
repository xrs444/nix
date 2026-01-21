# Summary: Home Manager configuration for user 'xrs444', setting up shell, git, and common development tools for Darwin and Linux systems.
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
      settings = {
        user.name = "Thomas Letherby";
        user.email = "xrs444@xrs444.net";
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "nano";
      };
      ignores = [ ".DS_Store" ];
    };
    # Fish configuration is managed by nix-darwin on macOS to prevent PATH issues
    fish.enable = pkgs.stdenv.isLinux;
    starship.enable = true;
    go.enable = true;
    rbenv.enable = true;
    atuin = {
      enable = true;
      enableFishIntegration = pkgs.stdenv.isLinux;
      enableZshIntegration = true;
    };
    yt-dlp.enable = true;
    # SSH configuration for thomas-local key
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        # Explicit default configuration to replace removed defaults
        "*" = {
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
        };
        "*.lan thomas-local@*" = {
          user = "thomas-local";
          identityFile =
            if pkgs.stdenv.isDarwin then "~/.ssh/thomas-local_key" else "/run/secrets/thomas-local-ssh-key";
        };
      };
    };
  };

  # Apps
  imports = [
    ../../common/apps/vscode
    ./shell/starship.nix
    ./shell/tmux.nix
    ./shell/fish.nix
  ];

  # Install non-standard fonts
  home.packages = with pkgs; [
    # Nerd Fonts for terminal and coding
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    nerd-fonts.hack
    nerd-fonts.iosevka
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
    direnv
    teams
    kustomize
    kubeconform
    pre-commit
    hugo
    openjdk
    ruby
    ansible
    cilium-cli
    cmctl
    fluxcd
    hubble
    kubectl
    kubeseal
    talosctl
    arping
    baobab
    nmap
    sops
    sshpass
    tfswitch
    tree
    yq
    yamllint
    _7zz
    brotli
    lz4
    lzo
    p7zip
    wimlib
    xz
    zstd
    iterm2
    wireshark
    openscad
    powershell
    pipx
    virtualenv
    just
    claude-code
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;

  # Deploy nix-sh.fish selector script to ~/.local/bin
  home.file.".local/bin/nix-sh.fish" = {
    source = builtins.path { path = ./../../../scripts/nix-sh.fish; };
    executable = true;
  };

  # Prevent Home Manager from overriding PATH
  home.sessionPath = [ ];

  # Set default shell preferences
  home.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "firefox";
    SOPS_AGE_KEY_FILE = "/Users/xrs444/.config/sops/age/keys.txt";
    KUBECONFIG = "/Users/xrs444/k8s/kubeconfig";
    TALOSCONFIG = "/Users/xrs444/k8s/talosconfig";
    # PATH is managed by nix-darwin - don't override it
  };

  # Enable Catppuccin theme globally
  # catppuccin = {
  #   enable = true;
  #   flavor = "mocha";
  # };

}

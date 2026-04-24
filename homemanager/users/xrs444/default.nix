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
    wezterm = {
      enable = true;
      extraConfig = ''
        local config = wezterm.config_builder()
        config.initial_cols = 120
        config.initial_rows = 28
        config.font_size = 12
        config.color_scheme = 'Catppuccin Mocha'
        config.font = wezterm.font 'SpaceMono Nerd Font'
        return config
      '';
    };
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
    ../../common/shell/atuin.nix
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
    (direnv.overrideAttrs (_: {
      doCheck = false;
    }))
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

  # Claude Code CLI settings
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "sonnet";
    permissions.allow = [
      "WebFetch"
      "WebSearch"
    ];
  };

  # SOPS config for ~/.claude secrets (kept separate from project secrets)
  home.file.".claude/.sops.yaml".text = ''
    creation_rules:
      - path_regex: secrets/.*\.yaml$
        age: age1rzatmse76n9mv975gyeydsj9pafl7mz9ndcznlc2zfwnl7g8x5pqv5haqt
  '';

  # MCP server wrapper scripts — decrypt SOPS credentials and launch containers
  home.file.".claude/scripts/run-ha-mcp.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      SECRETS=$(sops --decrypt "$HOME/.claude/secrets/mcp-credentials.yaml")
      HA_URL=$(echo "$SECRETS" | awk '/^homeassistant:/{f=1} f && /url:/{print $2; exit}' | tr -d '"')
      HA_TOKEN=$(echo "$SECRETS" | awk '/^homeassistant:/{f=1} f && /token:/{print $2; exit}' | tr -d '"')
      docker rm -f mcp-homeassistant 2>/dev/null || true
      exec docker run --rm -i --name "mcp-homeassistant" \
        -e HOMEASSISTANT_URL="$HA_URL" \
        -e HOMEASSISTANT_TOKEN="$HA_TOKEN" \
        ghcr.io/homeassistant-ai/ha-mcp:stable
    '';
  };

  home.file.".claude/scripts/run-firewalla-mcp.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      SECRETS=$(sops --decrypt "$HOME/.claude/secrets/mcp-credentials.yaml")
      FW_TOKEN=$(echo "$SECRETS" | awk '/^firewalla:/{f=1} f && /token:/{print $2; exit}' | tr -d '"')
      docker rm -f mcp-firewalla 2>/dev/null || true
      exec docker run --rm -i --name "mcp-firewalla" \
        -e FIREWALLA_MSP_ID=dn-j3almw \
        -e FIREWALLA_MSP_TOKEN="$FW_TOKEN" \
        amittell/firewalla-mcp-server:latest
    '';
  };

  # Enable font configuration
  fonts.fontconfig.enable = true;

  # Deploy nix-sh.fish selector script to ~/.local/bin
  # home.file.".local/bin/nix-sh.fish" = {
  #  source = builtins.path { path = ./../../../scripts/nix-sh.fish; };
  #  executable = true;
  # };

  # Prevent Home Manager from overriding PATH
  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  # Set default shell preferences
  home.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "chrome";
    SOPS_AGE_KEY_FILE = "/Users/xrs444/.config/sops/age/keys.txt";
    KUBECONFIG = "/Users/xrs444/k8s/kubeconfig";
    TALOSCONFIG = "/Users/xrs444/k8s/talosconfig";
    # PATH is managed by nix-darwin - don't override it
  };

  # catppuccin = {
  #   enable = true;
  #  flavor = "mocha";
  #   # VSCode extensions and theme are managed manually in common/apps/vscode
  #   # to use up-to-date marketplace versions; catppuccin module adds older pins
  #   vscode.profiles.default.enable = false;
  # };

}

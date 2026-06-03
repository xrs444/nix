# Summary: Home Manager configuration for user 'xrs444', setting up shell, git, and common development tools for Darwin and Linux systems.
{
  pkgs,
  lib,
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
    wireshark
    openscad
    powershell
    pipx
    virtualenv
    just
    claude-code
  ];

  # Claude Code CLI settings
  # PATH must be explicit — VSCode's extension host launches with a bare PATH
  # that excludes /usr/local/bin (docker/OrbStack) and nix profile paths (sops).
  home.file.".claude/settings.json".text =
    let
      mcpPath = "/usr/local/bin:/etc/profiles/per-user/xrs444/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    in
    builtins.toJSON {
      model = "opusplan";
      permissions.allow = [
        "WebFetch"
        "WebSearch"
      ];
      mcpServers = {
        homeassistant = {
          command = "/Users/xrs444/.claude/scripts/run-ha-mcp.sh";
          args = [];
          env = { PATH = mcpPath; };
        };
        firewalla = {
          command = "/Users/xrs444/.claude/scripts/run-firewalla-mcp.sh";
          args = [];
          env = { PATH = mcpPath; };
        };
        arr = {
          command = "/Users/xrs444/.claude/scripts/run-arr-mcp.sh";
          args = [];
          env = { PATH = mcpPath; };
        };
        omada = {
          command = "/Users/xrs444/.claude/scripts/run-omada-mcp.sh";
          args = [];
          env = { PATH = mcpPath; };
        };
      };
    };

  # SOPS config for ~/.claude secrets (kept separate from project secrets)
  home.file.".claude/.sops.yaml".text = ''
    creation_rules:
      - path_regex: secrets/.*\.yaml$
        age: age1rzatmse76n9mv975gyeydsj9pafl7mz9ndcznlc2zfwnl7g8x5pqv5haqt
  '';

  # MCP server wrapper scripts — decrypt SOPS credentials and launch containers
  home.file.".claude/scripts/run-omada-mcp.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      docker rm -f mcp-omada 2>/dev/null || true
      exec docker run --rm -i --name "mcp-omada" \
        -e OMADA_BASE_URL=https://omada.xrs444.net \
        -e OMADA_CLIENT_ID=680ae9cdd8da44bab937bfbeac61cf99 \
        -e OMADA_CLIENT_SECRET=09cbfcd6756843f89c8a1fe97412668f \
        -e OMADA_OMADAC_ID=44d12ba71e4a4c20a9ae0ba9450b329f \
        -e OMADA_STRICT_SSL=false \
        jmtvms/tplink-omada-mcp:latest
    '';
  };

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
        -e FIREWALLA_MSP_URL=https://dn-j3almw.firewalla.net \
        -e FIREWALLA_MSP_TOKEN="$FW_TOKEN" \
        amittell/firewalla-mcp-server:latest
    '';
  };

  home.file.".claude/scripts/run-arr-mcp.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      SECRETS=$(sops --decrypt "$HOME/.claude/secrets/mcp-credentials.yaml")
      RADARR_KEY=$(echo "$SECRETS" | awk '/^arr:/{f=1} f && /radarr_api_key:/{print $2; exit}' | tr -d '"')
      SONARR_KEY=$(echo "$SECRETS" | awk '/^arr:/{f=1} f && /sonarr_api_key:/{print $2; exit}' | tr -d '"')
      LIDARR_KEY=$(echo "$SECRETS" | awk '/^arr:/{f=1} f && /lidarr_api_key:/{print $2; exit}' | tr -d '"')
      docker rm -f mcp-arr 2>/dev/null || true
      exec docker run --rm -i --name "mcp-arr" \
        -v mcp-arr-npm-cache:/root/.npm \
        -e RADARR_URL="https://radarr.xrs444.net" \
        -e RADARR_API_KEY="$RADARR_KEY" \
        -e SONARR_URL="https://sonarr.xrs444.net" \
        -e SONARR_API_KEY="$SONARR_KEY" \
        -e LIDARR_URL="https://lidarr.xrs444.net" \
        -e LIDARR_API_KEY="$LIDARR_KEY" \
        node:20-alpine \
        npx --yes mcp-arr-server
    '';
  };

  # NOTE: knucklessg1/jellyfin-mcp was removed from Docker Hub and januszadlo/jellyfin-mcp
  # only supports HTTP transport (not stdio). Jellyfin MCP is disabled until a working
  # stdio-compatible image is found. Script kept as reference.
  home.file.".claude/scripts/run-jellyfin-mcp.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      SECRETS=$(sops --decrypt "$HOME/.claude/secrets/mcp-credentials.yaml")
      JF_TOKEN=$(echo "$SECRETS" | awk '/^jellyfin:/{f=1} f && /token:/{print $2; exit}' | tr -d '"')
      docker rm -f mcp-jellyfin 2>/dev/null || true
      exec docker run --rm -i --name "mcp-jellyfin" \
        -e TRANSPORT=stdio \
        -e JELLYFIN_BASE_URL="https://jellyfin.xrs444.net" \
        -e JELLYFIN_TOKEN="$JF_TOKEN" \
        januszadlo/jellyfin-mcp:latest
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

  catppuccin = {
    enable = true;
    flavor = "mocha";
    # VSCode extensions and theme are managed manually in common/apps/vscode
    # to use up-to-date marketplace versions; catppuccin module adds older pins
    vscode.profiles.default.enable = false;
    # catppuccin-nix reads the starship theme TOML via IFD at eval time.
    # On aarch64-darwin evaluating x86_64-linux targets the derivation isn't in
    # the local store, breaking nix flake check. Disable on Linux until the
    # catppuccin-starship x86_64-linux binary lands in a reachable cache.
    starship.enable = pkgs.stdenv.isDarwin;
  };

  # VSCode reads .extensions-immutable.json using a single readlink() call, not realpath().
  # home-manager creates two-level symlinks (ext → home-manager-files → nix-store), so the
  # single readlink doesn't match the fsPath in immutable.json. VSCode then skips the
  # immutable protection and marks every nix-managed extension as obsolete at startup,
  # preventing them from loading. This activation script collapses each symlink to a direct
  # pointer so readlink() and realpath() agree.
  home.activation.fixVscodeExtensionSymlinks = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ext_dir="$HOME/.vscode/extensions"
    if [ -d "$ext_dir" ]; then
      for link in "$ext_dir"/*/; do
        link="''${link%/}"
        if [ -L "$link" ]; then
          real=$(${pkgs.coreutils}/bin/realpath "$link" 2>/dev/null) || continue
          current=$(readlink "$link")
          if [ "$real" != "$current" ]; then
            ln -sfn "$real" "$link"
          fi
        fi
      done
      rm -f "$ext_dir/.obsolete"
    fi
  '';

}

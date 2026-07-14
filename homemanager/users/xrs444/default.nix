# Summary: Home Manager configuration for user 'xrs444', setting up shell, git, and common development tools for Darwin and Linux systems.
{
  pkgs,
  lib,
  stateVersion,
  username,
  hostName ? null,
  desktop ? null,
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
      settings = {
        # Explicit default configuration to replace removed defaults
        "*" = {
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
        };
        "*.lan thomas-local@*" = {
          User = "thomas-local";
          IdentityFile =
            if pkgs.stdenv.isDarwin then "~/.ssh/thomas-local_key" else "/run/secrets/thomas-local-ssh-key";
        };
      };
    };
  };

  # Apps + desktop (niri/gnome/etc.) when this host has a desktop environment
  imports = [
    ../../common/apps/vscode
    ../../common/shell/atuin.nix
    ./shell/starship.nix
    ./shell/tmux.nix
    ./shell/fish.nix
  ] ++ lib.optional (hostName == "xdt1-t") ./apps/obs.nix
    ++ lib.optional (builtins.isString desktop) ../../common/desktop;

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
    xz
    zstd
    wireshark
    openscad
    powershell
    pipx
    virtualenv
    just
    claude-code
    k9s
    vja
    nodejs
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    baobab
    vikunja-desktop
  ]
  # wimlib pulls in syslinux on Linux (for mkwinpeimg), which nixpkgs only
  # supports on i686-linux/x86_64-linux — evaluating it on aarch64-linux
  # (xlt1-t-vnixos) throws "not available on the requested hostPlatform".
  ++ lib.optional (pkgs.stdenv.hostPlatform.system != "aarch64-linux") wimlib;

  # Claude Code CLI settings
  home.file.".claude/settings.json".text =
    builtins.toJSON {
      model = "opusplan";
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
    autoEnable = true;
    flavor = "mocha";
    # VSCode extensions and theme are managed manually in common/apps/vscode
    # to use up-to-date marketplace versions; catppuccin module adds older pins
    vscode.profiles.default.enable = false;
    # OBS themes are managed manually in apps/obs.nix; catppuccin module now
    # also provides OBS support via autoEnable causing a conflicting definition.
    obs.enable = false;
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
  home.activation.openrgbVirtualControllers = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dest="$HOME/.config/OpenRGB/plugins/settings/virtual-controllers"
      $DRY_RUN_CMD mkdir -p "$dest"
      $DRY_RUN_CMD cp -f ${./openrgb/visual-map-xrs444.json} "$dest/xrs444"
      $DRY_RUN_CMD chmod 644 "$dest/xrs444"
    ''
  );

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

  # Headroom (family-agent plan §9) — compresses Claude Code's own
  # input/output tokens via verbosity steering + effort routing. Not in
  # nixpkgs; installed via pipx (already in home.packages) rather than a
  # hand-rolled derivation. Phase A adoption is this wrapper only — the
  # DeepSeek-facing proxy hop and Headroom MCP server are Phase B/C (see
  # plan §9 phasing; local MLX traffic deliberately never gets a Headroom
  # hop).
  home.activation.installHeadroom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! $DRY_RUN_CMD ${pkgs.pipx}/bin/pipx list --short 2>/dev/null | grep -q '^headroom-ai '; then
      $DRY_RUN_CMD ${pkgs.pipx}/bin/pipx install "headroom-ai[all]"
    fi
  '';

  # windmill-cli (wmill) — the actual CLI client for scripting against a
  # hosted Windmill instance (push/pull scripts, run flows). Not in nixpkgs
  # (only the 500MB self-hosted server/worker binary is, and it's Linux-only)
  # so this installs the npm package into ~/.npm-global, matching
  # home.sessionPath above. Cross-platform — applies on both xdt1-t and xlt1-t.
  home.activation.installWindmillCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! $DRY_RUN_CMD test -x "$HOME/.npm-global/bin/wmill"; then
      $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install --global --prefix "$HOME/.npm-global" windmill-cli
    fi
  '';

  # conf.d file (not programs.fish, which is Linux-only in fish.nix) so this
  # lands regardless — fish itself is enabled system-wide via nix-darwin
  # (hosts/darwin/default.nix) and auto-sources ~/.config/fish/conf.d/*.fish.
  home.file.".config/fish/conf.d/headroom.fish".text = ''
    if command -v headroom >/dev/null 2>&1
      alias claude "headroom wrap claude"
    end
  '';

}

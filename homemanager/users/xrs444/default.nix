# Summary: Home Manager configuration for user 'xrs444', setting up shell, git, and common development tools for Darwin and Linux systems.
{
  pkgs,
  lib,
  inputs,
  stateVersion,
  username,
  hostName ? null,
  desktop ? null,
  ...
}:
let
  # xcog1 is a headless LLM server, not a workstation — see
  # nix/docs/xcog1-llm-deployment-plan.md and the cerebrum Decision Log
  # (2026-08-07) for the core+marginal+diagnostics package split this gates.
  isServer = hostName == "xcog1";
  isXdt1t = hostName == "xdt1-t";
in
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
    # SSH configuration — declares which key is offered for which host so
    # plain `ssh <host>` picks the right identity with no manual `-i` flag.
    # Key material itself is provisioned separately (sops-nix): NixOS via
    # modules/users/xrs444.nix, Darwin via hosts/darwin/default.nix.
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      # `Host` patterns can ONLY match the hostname argument — OpenSSH has no
      # `user@host`-as-Host-pattern feature despite the tempting syntax (see
      # ssh_config(5) PATTERNS/Host: matched against "the hostname argument
      # given on the command line"). A `Host thomas-local@*`-style block
      # silently never matches on real OpenSSH (10.2p1 confirmed); it falls
      # straight through to ssh's own hardcoded default identities.
      #
      # Any block that needs to key off the *user* an invocation uses
      # (thomas-local vs. the xrs444 default, builder@, opc@, pi@) instead
      # uses a real `Match ... user <name>` block, written as an attribute
      # name literally starting with "Match " — home-manager's settings
      # module uses the attribute name verbatim as the block header when it
      # already starts with "Host " or "Match ", only auto-prefixing "Host "
      # otherwise (see home-manager's modules/programs/ssh.nix, the
      # `settings` option's `header` default). Confirmed working (both
      # positive and `!user` negated forms) via `ssh -F <test-config> -G`
      # before writing this.
      settings = {
        # Explicit default configuration to replace removed defaults
        "*" = {
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
        };
        # Default interactive identity for plain `ssh <host>.lan` (no
        # explicit user). Excludes every other special-purpose user that can
        # also target a *.lan host (thomas-local, builder, pi) — Match
        # blocks are independently additive (IdentityFile accumulates across
        # every block that matches, not first-wins), so without these
        # exclusions e.g. `ssh builder@xsvr1.lan` would get offered BOTH
        # xrs444_key and builder_key: harmless in that ssh just tries the
        # wrong one first and falls through, but noisy extra failed-auth
        # attempts are exactly what has tripped fail2ban on this fleet
        # before (bug-510/524/527) — worth avoiding, not just tolerating.
        # opc/nutanix/dog aren't listed: none of their blocks target a *.lan
        # host, so there's no overlap to exclude.
        "Match host *.lan !user thomas-local !user builder !user pi" = {
          User = "xrs444";
          # NixOS path matches sops.secrets."xrs444-ssh-key".path in
          # modules/users/xrs444.nix (custom path, not the /run/secrets
          # default — a custom `path` fully replaces the default location).
          IdentityFile =
            if pkgs.stdenv.isDarwin then "~/.ssh/xrs444_key" else "/home/xrs444/.ssh/xrs444_key";
          IdentitiesOnly = true;
        };
        # Reserved for explicit thomas-local@ invocations (automation/scripts).
        "Match host *.lan user thomas-local" = {
          User = "thomas-local";
          # See sops.secrets."thomas-local-ssh-key".path in modules/users/xrs444.nix —
          # was previously (incorrectly) pointing at the unused /run/secrets default.
          IdentityFile =
            if pkgs.stdenv.isDarwin then "~/.ssh/thomas-local_key" else "/home/xrs444/.ssh/thomas-local_key";
          IdentitiesOnly = true;
        };
      }
      # The remaining keys below are only usable on Darwin: their key material
      # is provisioned to ~/.ssh there (hosts/darwin/default.nix). On NixOS,
      # /etc/ssh/id_builder is owner=builder mode=0600 (see
      # modules/services/remotebuilds/default.nix), unreadable by xrs444, and
      # ntnx/ansible-brocade/oci/pi/obs-key have no NixOS-side use at all.
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        # `xsvr1-builder` is a bare alias (not a real hostname), so a plain
        # `Host` pattern works fine for it — only the explicit
        # `builder@xsvr1.lan` form needs `Match ... user builder`.
        "builder@xsvr1.lan xsvr1-builder" = {
          User = "builder";
          HostName = "xsvr1.lan";
          IdentityFile = "~/.ssh/builder_key";
          IdentitiesOnly = true;
        };
        "Match host xsvr1.lan user builder" = {
          IdentityFile = "~/.ssh/builder_key";
          IdentitiesOnly = true;
        };

        # Nutanix cluster.
        xntnx = {
          HostName = "172.25.1.100";
          User = "nutanix";
          IdentityFile = "~/.ssh/ntnx";
          IdentitiesOnly = true;
          StrictHostKeyChecking = "no";
        };

        # Legacy Brocade/Ruckus FastIron core switch (xswcore) — old enough to
        # need KexAlgorithms/PubkeyAcceptedKeyTypes/HostKeyAlgorithms
        # re-enabled; modern OpenSSH disables these by default.
        xswcore1 = {
          HostName = "172.18.4.100";
          User = "dog";
          Port = 22;
          IdentityFile = "~/.ssh/ansible-brocade_key";
          IdentitiesOnly = true;
          KexAlgorithms = "+diffie-hellman-group14-sha1";
          PubkeyAcceptedKeyTypes = "+ssh-rsa";
          HostKeyAlgorithms = "+ssh-rsa";
        };
        "xswcore1.x.xrs444.net" = {
          IdentityFile = "~/.ssh/ansible-brocade_key";
          IdentitiesOnly = true;
          KexAlgorithms = "+diffie-hellman-group14-sha1";
          PubkeyAcceptedKeyTypes = "+ssh-rsa";
          HostKeyAlgorithms = "+ssh-rsa";
        };
        # A second, older legacy device on the same admin key — needs an even
        # older KEX (group1-sha1). No known hostname, IP only.
        "172.18.11.249" = {
          IdentityFile = "~/.ssh/ansible-brocade_key";
          IdentitiesOnly = true;
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          PubkeyAcceptedKeyTypes = "+ssh-rsa";
          HostKeyAlgorithms = "+ssh-rsa";
        };

        # Oracle Cloud default per-instance admin user (opc), separate from
        # the builder/deploy service identities that also reach vocibuild.
        "Match host vocibuild.xrs444.net user opc" = {
          IdentityFile = "~/.ssh/oci";
          IdentitiesOnly = true;
        };

        # Firewalla's fixed default SSH username — matched by user only, not
        # hostname, since it's not a Nix-managed host with a fixed address.
        "Match user pi" = {
          IdentityFile = "~/.ssh/pi";
          IdentitiesOnly = true;
        };

        # BetterTouchTool automation scripts on xlt1-t reaching xdt1-t as
        # xrs444 (see modules/users/xrs444.nix for the matching
        # authorized_key, gated to hostname == "xdt1-t").
        xdt1-t-obs = {
          HostName = "xdt1-t.lan";
          User = "xrs444";
          IdentityFile = "~/.ssh/obs-key";
          IdentitiesOnly = true;
        };
      };
    };
  } // lib.optionalAttrs (!isServer) {
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
    starship.enable = true;
    go.enable = true;
    rbenv.enable = true;
    yt-dlp.enable = true;
  } // lib.optionalAttrs isXdt1t {
    # Push-to-talk voice-to-text daemon (voxtype.io). Package comes from
    # nixpkgs (already wraps wtype/dotool/ydotool/xclip/xdotool into
    # PATH); only the upstream flake's Home Manager module is used (see
    # imports below), for the systemd user service + declarative
    # config.toml/model management. hotkey.enabled = false: push-to-talk
    # is triggered by a Mod+Shift+V niri keybind running `voxtype record
    # toggle` (homemanager/common/desktop/niri/default.nix), not voxtype's
    # own evdev listener — avoids adding xrs444 to the `input` group
    # (which would let the daemon read every keystroke on the machine,
    # not just the dictation hotkey).
    voxtype = {
      enable = true;
      package = pkgs.voxtype;
      engine = "whisper";
      model.name = "base.en";
      service.enable = true;
      settings.hotkey.enabled = false;
    };
  };

  # Apps + desktop (niri/gnome/etc.) when this host has a desktop environment.
  # xcog1 (isServer) skips vscode/atuin/syncthing/starship entirely — none of
  # it is relevant to a headless LLM server, and vscode's Python extension
  # was what dragged Django's test suite into xcog1's build (bug-526).
  imports = lib.optionals (!isServer) [
    ../../common/apps/vscode
    ../../common/shell/atuin.nix
    ../../common/syncthing.nix
    ./shell/starship.nix
  ] ++ [
    ./shell/tmux.nix
    ./shell/fish.nix
  ] ++ lib.optionals isXdt1t [
    ./apps/obs.nix
    ./apps/rip.nix
    inputs.voxtype.homeManagerModules.default
  ]
    ++ lib.optional (builtins.isString desktop) ../../common/desktop;

  # Core + marginal admin tooling — every host gets this, including xcog1.
  # See homemanager/users/xrs444/default.nix's isServer split and
  # nix/docs/xcog1-llm-deployment-plan.md for the full core/marginal/
  # diagnostics rationale (2026-08-07).
  home.packages =
    with pkgs;
    [
      just
      sops
      claude-code
      tree
      yq
      yamllint
      k9s
      # Diagnostics-only, requested for if/when xcog1 needs them — nmap and
      # bitwarden-cli are cheap and cached for aarch64-darwin; firefox is
      # NOT here (nixpkgs' aarch64-darwin firefox isn't cache-built —
      # confirmed 404 on cache.nixos.org — so it'd be an hours-long local
      # compile; it's a Homebrew cask on xcog1 instead, see that host's
      # dedicated homebrew block).
      nmap
      bitwarden-cli
    ]
    ++ lib.optionals (!isServer) [
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
      sshpass
      tfswitch
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
      vja
      nodejs
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
    baobab
    vikunja-desktop
    # Obsidian is already installed via brew on darwin (packages-darwin/brew-packages.nix);
    # this brings xdt1-t to parity so the vault (synced via services.syncthing below) has
    # the same editor available. Unfree — see allowUnfreePredicate in this host's config.
    obsidian
  ]
  # Google Drive sync for xrs444's own account. Unfree (allowUnfree already
  # set in hosts/nixos/xdt1-t/default.nix). No Nautilus extension here —
  # xdt1-t's file manager is Thunar (see desktop.nix's gvfs comment), which
  # insync-nautilus doesn't target; the standalone app is still fully
  # functional without it. First run needs an interactive `insync start`
  # login (OAuth) — not something Nix can provision declaratively.
  # x86_64-linux only — nixpkgs has no aarch64-linux build, which broke
  # eval for xlt1-t-vnixos once integrated Home Manager (base-nixos.nix)
  # started evaluating this config for real instead of it being an
  # unbuilt standalone homeConfigurations output.
  ++ lib.optional (pkgs.stdenv.hostPlatform.system == "x86_64-linux") insync
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

  # vja (Vikunja CLI) server config — non-secret. The API token is decrypted
  # by sops-nix (modules/users/xrs444.nix on Linux, hosts/darwin/default.nix
  # on Darwin) to its default /run/secrets/<name> location, then symlinked
  # into ~/.config/vja/token.json below. Skipped on isServer — vja's package
  # is in the !isServer home.packages block above, no client to use this.
  home.file.".config/vja/config.rc" = lib.mkIf (!isServer) {
    text = ''
      [application]
      frontend_url=https://vikunja.xrs444.net/
      api_url=https://vikunja.xrs444.net/api/v1
    '';
  };

  # Symlink the sops-managed token into vja's expected location.
  # Deliberately not a sops `path` override: sops places secrets as root, so
  # a custom path under ~/.config/vja would force that directory to be
  # created root-owned, racing with this same-directory config.rc write
  # above (unprivileged) and aborting home-manager's activation partway —
  # which is what silently wiped VS Code's extension symlinks on xlt1-t.
  home.activation.linkVjaToken = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD ln -sfn ${
        if pkgs.stdenv.isDarwin then
          "/run/secrets/vikunja-api-token"
        else
          "/run/secrets/vikunja-api-token-xrs444"
      } "$HOME/.config/vja/token.json"
    ''
  );

  # Enable font configuration — no nerd-fonts installed on isServer, so no
  # fontconfig cache needed there either.
  fonts.fontconfig.enable = !isServer;

  # Deploy nix-sh.fish selector script to ~/.local/bin
  # home.file.".local/bin/nix-sh.fish" = {
  #  source = builtins.path { path = ./../../../scripts/nix-sh.fish; };
  #  executable = true;
  # };

  # Obsidian vault workflow scripts (see the "obsidian vault" plan for full
  # context). Cross-platform: both use $HOME internally so the same script
  # works unmodified on xlt1-t (/Users/xrs444) and xdt1-t (/home/xrs444).
  #
  # publish-blog: one-way rsync of vault Blog/*.md -> site repo
  # content/posts/, then git commit+push. Cloudflare Pages builds on push,
  # so this script's job ends at the push.
  home.file.".local/bin/publish-blog" = lib.mkIf (!isServer) {
    source = ./scripts/publish-blog.sh;
    executable = true;
  };

  # sync-vikunja-tasks: one-way mirror of the Vikunja "HomeProd" project
  # into a generated, read-only Tasks/HomeProd.md in the vault. Vikunja
  # stays the single source of truth for task management (user + Claude +
  # future Hermes-t) — see plan doc for why this is one-way, not the
  # two-way obsidian-vikunja-plugin (its "Obsidian always wins"/single-user
  # conflict model and broken bucket/project support make it unsafe for
  # multi-client use).
  home.file.".local/bin/sync-vikunja-tasks" = lib.mkIf (!isServer) {
    source = ./scripts/sync-vikunja-tasks.sh;
    executable = true;
  };

  # Refresh timer for sync-vikunja-tasks, ~every 15 min. launchd doesn't
  # expand $HOME in ProgramArguments, so the absolute path is rebuilt here
  # the same way home.homeDirectory is above rather than depending on
  # `config` (not in this module's function head).
  launchd.agents.sync-vikunja-tasks = lib.mkIf (pkgs.stdenv.isDarwin && !isServer) {
    enable = true;
    config = {
      ProgramArguments = [
        "${if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"}/.local/bin/sync-vikunja-tasks"
      ];
      StartInterval = 900;
      StandardOutPath = "${
        if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"
      }/Library/Logs/sync-vikunja-tasks.log";
      StandardErrorPath = "${
        if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"
      }/Library/Logs/sync-vikunja-tasks.log";
    };
  };

  systemd.user.services.sync-vikunja-tasks = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Sync Vikunja HomeProd tasks into Obsidian vault";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/sync-vikunja-tasks";
    };
  };

  systemd.user.timers.sync-vikunja-tasks = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Timer for sync-vikunja-tasks";
    Timer = {
      OnStartupSec = "2m";
      OnUnitActiveSec = "15m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Prevent Home Manager from overriding PATH
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
  ];

  # Set default shell preferences
  home.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "firefox";
    SOPS_AGE_KEY_FILE = "/Users/xrs444/.config/sops/age/keys.txt";
    KUBECONFIG = "/Users/xrs444/k8s/kubeconfig";
    TALOSCONFIG = "/Users/xrs444/k8s/talosconfig";
    # PATH is managed by nix-darwin - don't override it
  };

  # No theming on isServer — none of catppuccin's targets (vscode, starship,
  # obs) are enabled there. Leaving this unset lets the sharedModules default
  # (autoEnable = mkDefault false) stand, which is a true no-op.
  catppuccin = lib.mkIf (!isServer) {
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

      # Mirror the same profile the systemd service loads (nix/hosts/nixos/xdt1-t/openrgb/xrs444.orp)
      # into the GUI's own config dir -- the GUI's Profiles list only reads from its local
      # ~/.config/OpenRGB, not /var/lib/OpenRGB (the service's --config dir), so without this
      # the "xrs444" profile never appears as a loadable option in the app.
      $DRY_RUN_CMD mkdir -p "$HOME/.config/OpenRGB"
      $DRY_RUN_CMD cp -f ${../../../hosts/nixos/xdt1-t/openrgb/xrs444.orp} "$HOME/.config/OpenRGB/xrs444.orp"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/OpenRGB/xrs444.orp"
    ''
  );

  home.activation.fixVscodeExtensionSymlinks = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
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
    ''
  );

  # Headroom (family-agent plan §9) — compresses Claude Code's own
  # input/output tokens via verbosity steering + effort routing. Not in
  # nixpkgs; installed via pipx (already in home.packages) rather than a
  # hand-rolled derivation. Phase A adoption is this wrapper only — the
  # DeepSeek-facing proxy hop and Headroom MCP server are Phase B/C (see
  # plan §9 phasing; local MLX traffic deliberately never gets a Headroom
  # hop).
  home.activation.installHeadroom = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! $DRY_RUN_CMD ${pkgs.pipx}/bin/pipx list --short 2>/dev/null | grep -q '^headroom-ai '; then
        # litellm (a headroom-ai dep) builds Rust extensions via maturin, which
        # needs a C linker. This activation script's PATH is deliberately
        # minimal (coreutils etc. only) and has no compiler on it, so pull in
        # the system toolchain (Xcode CLT's /usr/bin/cc on Darwin) just for
        # this install. Best-effort and non-fatal: a failed optional dev-tool
        # install must never abort the rest of activation — this step used to
        # be fatal and its failure skipped every later step (VS Code extension
        # symlinking, settings.json writability, etc.), which is what broke
        # VS Code on xlt1-t.
        PATH="/usr/bin:$PATH" $DRY_RUN_CMD ${pkgs.pipx}/bin/pipx install "headroom-ai[all]" \
          || echo "Warning: headroom-ai install failed, continuing activation" >&2
      fi
    ''
  );

  # windmill-cli (wmill) — the actual CLI client for scripting against a
  # hosted Windmill instance (push/pull scripts, run flows). Not in nixpkgs
  # (only the 500MB self-hosted server/worker binary is, and it's Linux-only)
  # so this installs the npm package into ~/.npm-global, matching
  # home.sessionPath above. Cross-platform — applies on both xdt1-t and xlt1-t.
  home.activation.installWindmillCli = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! $DRY_RUN_CMD test -x "$HOME/.npm-global/bin/wmill"; then
        # windmill-cli's postinstall (esbuild) shells out to a bare `node`.
        # This activation script's PATH is deliberately minimal and has no
        # node on it, so pull in nodejs's own bin dir just for this install.
        # Best-effort and non-fatal — see installHeadroom above for why a
        # failed optional dev-tool install must never abort the rest of
        # activation.
        PATH="${pkgs.nodejs}/bin:$PATH" $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install --global --prefix "$HOME/.npm-global" windmill-cli \
          || echo "Warning: windmill-cli install failed, continuing activation" >&2
        # npm (at least under this activation script's environment) installs
        # windmill-cli's bin script without the executable bit, so the
        # `test -x` guard above never sees it as installed and this step
        # re-runs (and fails) every single activation. Force it executable.
        $DRY_RUN_CMD chmod +x "$HOME/.npm-global/lib/node_modules/windmill-cli/esm/main.js" 2>/dev/null || true
      fi
    ''
  );

  # conf.d file (not programs.fish, which is Linux-only in fish.nix) so this
  # lands regardless — fish itself is enabled system-wide via nix-darwin
  # (hosts/darwin/default.nix) and auto-sources ~/.config/fish/conf.d/*.fish.
  # Skipped on isServer — headroom isn't installed there (installHeadroom is
  # gated too), and the alias would just always fall through its own guard.
  home.file.".config/fish/conf.d/headroom.fish" = lib.mkIf (!isServer) {
    text = ''
      if command -v headroom >/dev/null 2>&1
        alias claude "headroom wrap claude"
      end
    '';
  };

  # Ensure the Hugo site repo is present so publish-blog (above) has
  # somewhere to push into. Best-effort and non-fatal — see installHeadroom
  # above for why an optional setup step must never abort the rest of
  # activation. The theme (ananke) is a git submodule, hence --recurse-submodules.
  home.activation.cloneSite = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/site/xrs444/.git" ]; then
        $DRY_RUN_CMD mkdir -p "$HOME/site"
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone --recurse-submodules \
          https://github.com/xrs444/xrs444-site "$HOME/site/xrs444" \
          || echo "Warning: xrs444-site clone failed, continuing activation" >&2
      fi
    ''
  );

  # Scaffold the Obsidian vault's working folders. Cheap and idempotent —
  # runs every activation, just mkdir -p. The vault itself is synced in by
  # Syncthing (brew cask on darwin, services.syncthing on xdt1-t), so this
  # only creates subfolders once the vault root exists; if Syncthing hasn't
  # synced yet on a fresh host, this is a harmless no-op until it has.
  # Skipped on isServer — xcog1 doesn't import common/syncthing.nix, so no
  # vault will ever appear there.
  home.activation.obsidianVaultScaffold = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      vault="$HOME/Documents/obsidian/xrs444"
      if [ -d "$vault" ]; then
        $DRY_RUN_CMD mkdir -p "$vault/Memory/claude-code" "$vault/Memory/basic-memory" \
          "$vault/Memory/hermes-t" "$vault/Tasks" "$vault/data"
      fi
    ''
  );

  # Symlink this Claude Code instance's native per-project memory
  # (~/.claude/projects/<slug>/memory) into the vault's Memory/claude-code,
  # so the real files live in the vault (Syncthing-carried across hosts)
  # and memory is editable/reviewable in Obsidian. <slug> is the repo's
  # absolute path with every "/" replaced by "-" (observed Claude Code
  # convention). This repo is checked out at the same relative location on
  # every host ($HOME/Repositories/HomeProd), so the slug — which differs
  # per host because $HOME differs (/Users/... vs /home/...) — is computed
  # at activation time rather than hard-coded.
  # Skipped on isServer along with obsidianVaultScaffold above — gating both
  # (rather than leaving this one's own runtime guard to no-op) also avoids
  # entryAfter referencing a dag step that was never defined.
  home.activation.linkClaudeMemory = lib.mkIf (!isServer) (
    lib.hm.dag.entryAfter [ "obsidianVaultScaffold" ] ''
      repo_path="$HOME/Repositories/HomeProd"
      slug=$(printf '%s' "$repo_path" | tr '/' '-')
      claude_memory_dir="$HOME/.claude/projects/$slug/memory"
      vault_memory_dir="$HOME/Documents/obsidian/xrs444/Memory/claude-code"

      if [ -d "$HOME/Documents/obsidian/xrs444" ]; then
        $DRY_RUN_CMD mkdir -p "$vault_memory_dir"

        if [ -d "$claude_memory_dir" ] && [ ! -L "$claude_memory_dir" ]; then
          # One-time migration: move the real files into the vault, then
          # replace the original location with a symlink. Best-effort —
          # a failure here must not abort the rest of activation.
          $DRY_RUN_CMD sh -c 'cp -na "$1"/. "$2"/ && rm -rf "$1"' _ \
            "$claude_memory_dir" "$vault_memory_dir" \
            || echo "Warning: claude-code memory migration into vault failed, continuing activation" >&2
        fi

        if [ ! -e "$claude_memory_dir" ] || [ -L "$claude_memory_dir" ]; then
          $DRY_RUN_CMD mkdir -p "$(dirname "$claude_memory_dir")"
          $DRY_RUN_CMD ln -sfn "$vault_memory_dir" "$claude_memory_dir"
        fi
      else
        echo "linkClaudeMemory: vault not present at $HOME/Documents/obsidian/xrs444 yet (Syncthing not synced?), skipping" >&2
      fi
    ''
  );

}

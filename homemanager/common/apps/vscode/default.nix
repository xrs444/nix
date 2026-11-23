{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv) isLinux isDarwin;
  vscodeUserDir =
    if isLinux then
      "${config.xdg.configHome}/Code/User"
    else if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Code/User"
    else
      throw "Unsupported platform";

  # Shared settings, applied to every profile.
  commonSettings = {
    # Common settings for all platforms
    "editor.fontFamily" = "'SpaceMono Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
    "workbench.settings.applyToAllProfiles" = [ "editor.fontFamily" ];
    "git.enableSmartCommit" = true;
    "git.confirmSync" = false;
    "workbench.colorTheme" = "Catppuccin Mocha";
    "catppuccin-icons.hidesExplorerArrows" = false;
    "catppuccin-icons.specificFolders" = true;
    "catppuccin-icons.monochrome" = false;
    "files.autoSave" = "afterDelay";
    "files.autoSaveDelay" = 60000;
    "cSpell.diagnosticLevel" = "Hint";
    "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
    "editor.fontSize" = 16;
    "editor.fontLigatures" = true;
    "editor.fontWeight" = "400";
    "editor.guides.bracketPairs" = true;
    "editor.guides.bracketPairsHorizontal" = true;
    "editor.inlineSuggest.enabled" = true;
    "editor.renderWhitespace" = "all";
    "editor.rulers" = [
      80
      88
    ];
    "editor.semanticHighlighting.enabled" = true;
    "explorer.confirmDragAndDrop" = false;
    "extensions.ignoreRecommendations" = true;
    "[dockerfile]"."editor.quickSuggestions.strings" = true;
    "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
    "[nix]"."editor.formatOnSave" = true;
    "[nix]"."editor.tabSize" = 2;
    "[python]"."editor.formatOnType" = true;
    "[xml]"."editor.defaultFormatter" = "DotJoshJohnson.xml";
    "files.insertFinalNewline" = true;
    "files.trimTrailingWhitespace" = true;
    "git.openRepositoryInParentFolders" = "always";
    "githubPullRequests.pullBranch" = "never";
    "markdown.preview.breaks" = true;
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "nix.serverSettings" = {
      "nil" = {
        "formatting" = {
          "command" = [ "nixfmt" ];
        };
      };
    };
    "partialDiff.enableTelemetry" = false;
    "projectManager.git" = {
      baseFolders = [
        "~/Repositories"
      ];
      maxDepthRecursion = 5;
    };
    "redhat.telemetry.enabled" = false;
    "security.workspace.trust.untrustedFiles" = "open";
    "shellcheck.run" = "onSave";
    "shellformat.useEditorConfig" = true;
    "telemetry.feedback.enabled" = false;
    "telemetry.telemetryLevel" = "off";
    "extensions.autoCheckUpdates" = false;
    "update.mode" = "none";
    "workbench.iconTheme" = "catppuccin-mocha";
    "workbench.tree.indent" = 20;
    "workbench.startupEditor" = "none";
    "workbench.editor.empty.hint" = "hidden";
    # Kubernetes settings
    "vs-kubernetes.crd-code-completion" = "enabled";
    # Claude Code specific settings
    "claudeCode.selectedModel" = "sonnet";
  };

  # Settings shared by every profile: common settings plus per-platform overrides.
  settings =
    commonSettings
    // lib.optionalAttrs isDarwin {
      "terminal.integrated.defaultProfile.osx" = "fish";
      "terminal.integrated.env.osx" = { };
      "window.controlsStyle" = "native";
    }
    // lib.optionalAttrs isLinux {
      "terminal.integrated.env.linux" = { };
      "window.controlsStyle" =
        if config.wayland.windowManager.hyprland.enable then "hidden" else "native";
    };

  # Extensions installed in every profile: theming, git, remote access, Claude Code,
  # and small single-purpose utilities cheap enough to always have loaded.
  baseExtensions = with pkgs; [
    vscode-marketplace.anthropic.claude-code
    vscode-marketplace.pawelhuryn.claude-usage-phuryn
    vscode-marketplace-release.eamodio.gitlens
    vscode-marketplace.codezombiech.gitignore
    vscode-marketplace.alefragnani.project-manager
    vscode-marketplace.github.vscode-pull-request-github
    vscode-marketplace.catppuccin.catppuccin-vsc
    vscode-marketplace.catppuccin.catppuccin-vsc-icons
    vscode-marketplace.editorconfig.editorconfig
    vscode-marketplace.streetsidesoftware.code-spell-checker
    vscode-marketplace.aaron-bond.better-comments
    vscode-marketplace.esbenp.prettier-vscode
    vscode-marketplace.ms-vscode-remote.remote-ssh
    vscode-marketplace.ms-vscode-remote.remote-ssh-edit
    vscode-marketplace.ms-vscode.remote-explorer
    vscode-marketplace.dotjoshjohnson.xml
    vscode-marketplace.tamasfe.even-better-toml
    vscode-marketplace.moshfeu.compare-folders
    vscode-marketplace.ryu1kn.partial-diff
  ];

  # Nix / Ansible / Terraform / Kubernetes / systemd tooling.
  infraExtensions = with pkgs; [
    vscode-marketplace.jnoortheen.nix-ide
    vscode-marketplace.jeff-hykin.better-nix-syntax
    vscode-marketplace.redhat.ansible
    vscode-marketplace.dhoeric.ansible-vault
    vscode-marketplace.redhat.vscode-commons
    vscode-marketplace.redhat.vscode-yaml
    vscode-marketplace.hashicorp.terraform
    vscode-marketplace.ms-kubernetes-tools.vscode-kubernetes-tools
    vscode-marketplace.coolbear.systemd-unit-file
    vscode-marketplace.mkhl.direnv
    vscode-marketplace.nefrob.vscode-just-syntax
    vscode-marketplace.tobiashochguertel.just-formatter
    vscode-marketplace.fill-labs.dependi
    vscode-marketplace.nico-castell.linux-desktop-file
    vscode-marketplace.github.vscode-github-actions
    vscode-marketplace.sanjulaganepola.github-local-actions
  ];

  # Docker / container tooling.
  containerExtensions = with pkgs; [
    vscode-marketplace.ms-azuretools.vscode-containers
    vscode-marketplace.ms-vscode-remote.remote-containers
    vscode-marketplace.jeff-hykin.better-dockerfile-syntax
  ];

  # Python language tooling.
  pythonExtensions = with pkgs; [
    vscode-marketplace.ms-python.python
    vscode-marketplace.ms-python.debugpy
    vscode-marketplace.ms-python.vscode-pylance
    vscode-marketplace.ms-python.vscode-python-envs
  ];

  # Shell scripting (bash/fish/powershell).
  shellExtensions = with pkgs; [
    vscode-marketplace.bmalehorn.vscode-fish
    vscode-marketplace.foxundermoon.shell-format
    vscode-marketplace.mads-hartmann.bash-ide-vscode
    vscode-marketplace.timonwong.shellcheck
    vscode-marketplace.meronz.manpages
    vscode-marketplace.ms-vscode.powershell
  ];

  # Docs/writing (markdown, mdx, hugo, csv).
  docsExtensions = with pkgs; [
    vscode-marketplace.unifiedjs.vscode-mdx
    vscode-marketplace.xyc.vscode-mdx-preview
    vscode-marketplace.yzhang.markdown-all-in-one
    vscode-marketplace.davidanson.vscode-markdownlint
    vscode-marketplace.marp-team.marp-vscode
    vscode-marketplace.budparr.language-hugo-vscode
    vscode-marketplace.rusnasonov.vscode-hugo
    vscode-marketplace.viktorzetterstrom.non-breaking-space-highlighter
    vscode-marketplace.xshrim.txt-syntax
    vscode-marketplace.mechatroner.rainbow-csv
    vscode-marketplace.janisdd.vscode-edit-csv
    vscode-marketplace.jeff-hykin.better-csv-syntax
    vscode-marketplace.griimick.vhs
    vscode-marketplace.jeff-hykin.polacode-2019
  ];

  # Native C/C++ debugging + pairing, Linux only (matches prior gating).
  nativeDevExtensions = with pkgs; [
    vscode-extensions.ms-vscode.cpptools-extension-pack
    vscode-extensions.ms-vsliveshare.vsliveshare
    vscode-extensions.vadimcn.vscode-lldb
  ];

  # Common profile shape: shared settings + base extensions + task-specific extras.
  # enableExtensionUpdateCheck/enableUpdateCheck are only honored on the
  # "default" profile by home-manager; commonSettings already sets the
  # equivalent "extensions.autoCheckUpdates"/"update.mode" keys directly so
  # every profile gets the same effect without the module's per-profile warning.
  mkProfile = extraExtensions: {
    userSettings = settings;
    extensions = baseExtensions ++ extraExtensions;
  };
in
{

  home = {
    file = {
    };
    # Packages that are used by some of the extensions below
    packages = with pkgs; [
      bash-language-server
      meld
      nil
      nixfmt
      nodejs_24
      python3
      uv
      shellcheck
      shfmt
    ];
  };

  programs.vscode = {
    enable = true;
    profiles = {
      # Lightweight default: theming, git, remote access, Claude Code — no
      # task-specific language servers, so this is what VS Code opens with.
      default = mkProfile [ ];
      infra = mkProfile infraExtensions;
      containers = mkProfile containerExtensions;
      python = mkProfile pythonExtensions;
      shell = mkProfile shellExtensions;
      docs = mkProfile docsExtensions;
    }
    // lib.optionalAttrs isLinux {
      native-dev = mkProfile nativeDevExtensions;
    };
    # mutableExtensionsDir only has an effect when "default" is the sole
    # profile, per the home-manager module — moot now that we declare more.
    package = pkgs.unstable.vscode;
  };

  # Remove stale settings.json.backup before home-manager tries to create it,
  # since makeVSCodeSettingsWritable leaves a real file that triggers a backup each run.
  home.activation.cleanVSCodeBackup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f "${vscodeUserDir}/settings.json.backup"
  '';

  # fixVscodeExtensionSymlinks (below) rewrites extension symlinks from the two-level
  # "ext → home-manager-files → nix-store" chain into direct "ext → nix-store" symlinks.
  # check-link-targets.sh only recognises *-home-manager-files/* paths as HM-owned, so on
  # the next generation these direct-store symlinks look unowned. Symlinks are not eligible
  # for the backupFileExtension path (guarded by [[ ! -L ]]), causing an unconditional
  # "would be clobbered" error. Fix: remove these rewritten symlinks before checkLinkTargets
  # so linkGeneration can recreate them cleanly (pointing through home-manager-files).
  #
  # Only applies when $ext_dir is itself a real (non-symlink) directory containing one
  # symlink per extension — the model under mutableExtensionsDir=true with a single
  # "default" profile. With multiple profiles declared (as here), mutableExtensionsDir is
  # a no-op and home-manager instead symlinks $ext_dir itself straight into a merged
  # nix-store extensions directory; iterating into that immutable store path and trying to
  # rm entries inside it fails with "Read-only file system" (not a permissions error —
  # genuinely nothing to clean up in that model, since $ext_dir is already one clean
  # symlink). Skip entirely when $ext_dir is a symlink.
  home.activation.cleanRewrittenVSCodeExtensions = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ext_dir="$HOME/.vscode/extensions"
    if [ -d "$ext_dir" ] && [ ! -L "$ext_dir" ]; then
      for link in "$ext_dir"/*/; do
        link="''${link%/}"
        if [ -L "$link" ]; then
          target=$(readlink "$link")
          case "$target" in
            /nix/store/*-home-manager-files/*) ;;
            /nix/store/*) $DRY_RUN_CMD rm -f "$link" ;;
          esac
        fi
      done
    fi
  '';

  # Make settings.json writable by replacing symlink with a copy
  home.activation.makeVSCodeSettingsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="${vscodeUserDir}/settings.json"

    # If it's a symlink, replace it with a writable copy
    if [ -L "$SETTINGS_FILE" ]; then
      echo "Making VSCode settings.json writable..."
      SETTINGS_TARGET=$(readlink "$SETTINGS_FILE")
      $DRY_RUN_CMD rm -f "$SETTINGS_FILE"
      $DRY_RUN_CMD cp "$SETTINGS_TARGET" "$SETTINGS_FILE"
      $DRY_RUN_CMD chmod u+w "$SETTINGS_FILE"
    fi
  '';
}

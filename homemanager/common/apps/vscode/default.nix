# This file contains only the VS Code-related configuration split from the original default.nix.
# It is not intended to be used standalone; import it from your main config if needed.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (pkgs.stdenv) isLinux isDarwin;
  vscodeUserDir =
    if isLinux then
      "${config.xdg.configHome}/Code/User"
    else if isDarwin then
      "/Users/${username}/Library/Application Support/Code/User"
    else
      throw "Unsupported platform";
in
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      userSettings = {
        "terminal.integrated.defaultProfile.osx" = "fish";
        "terminal.integrated.env.linux" = {};
        "terminal.integrated.env.osx" = {};
        "editor.fontFamily" = "'SpaceMono Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace";
        "workbench.settings.applyToAllProfiles" = [ "editor.fontFamily" ];
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "catppuccin-icons.hidesExplorerArrows" = false;
        "catppuccin-icons.specificFolders" = true;
        "catppuccin-icons.monochrome" = false;
        "chat.mcp.autostart" = "newAndOutdated";
        "chat.mcp.discovery.enabled" = true;
        "chat.mcp.enabled" = true;
        "cline.chromeExecutablePath" = "/run/current-system/sw/bin/brave";
        "cSpell.diagnosticLevel" = "Hint";
        "dart.updateDevTools" = false;
        "dart.checkForSdkUpdates" = false;
        "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
        "editor.fontSize" = 16;
        "editor.fontLigatures" = true;
        "editor.fontWeight" = "400";
        "editor.guides.bracketPairs" = true;
        "editor.guides.bracketPairsHorizontal" = true;
        "editor.inlineSuggest.enabled" = true;
        "editor.renderWhitespace" = "all";
        "editor.rulers" = [ 80 88 ];
        "editor.semanticHighlighting.enabled" = true;
        "explorer.confirmDragAndDrop" = false;
        "extensions.ignoreRecommendations" = true;
        "[dart]"."editor.formatOnSave" = true;
        "[dart]"."editor.formatOnType" = true;
        "[dart]"."editor.rulers" = [ 80 ];
        "[dart]"."editor.selectionHighlight" = false;
        "[dart]"."editor.suggest.snippetsPreventQuickSuggestions" = false;
        "[dart]"."editor.suggestSelection" = "first";
        "[dart]"."editor.tabCompletion" = "onlySnippets";
        "[dart]"."editor.wordBasedSuggestions" = "off";
        "[dockerfile]"."editor.quickSuggestions.strings" = true;
        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
        "[nix]"."editor.formatOnSave" = true;
        "[nix]"."editor.tabSize" = 2;
        "[python]"."editor.formatOnType" = true;
        "[xml]"."editor.defaultFormatter" = "DotJoshJohnson.xml";
        "files.insertFinalNewline" = true;
        "files.trimTrailingWhitespace" = true;
        "git.openRepositoryInParentFolders" = "always";
        "github.copilot.chat.agent.thinkingTool" = true;
        "github.copilot.chat.codesearch.enabled" = true;
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
            "~/Chainguard"
            "~/Development"
            "~/Websites"
            "~/Zero"
          ];
          maxDepthRecursion = 5;
        };
        "redhat.telemetry.enabled" = false;
        "security.workspace.trust.untrustedFiles" = "open";
        "shellcheck.run" = "onSave";
        "shellformat.useEditorConfig" = true;
        "telemetry.feedback.enabled" = false;
        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.fontSize" = 16;
        "terminal.integrated.fontFamily" = "SpaceMono Nerd Font Mono";
        "terminal.integrated.fontWeight" = "400";
        "terminal.integrated.fontWeightBold" = "600";
        "terminal.integrated.scrollback" = 10240;
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.cursorBlinking" = true;
        "update.mode" = "none";
        "vsicons.dontShowNewVersionMessage" = true;
        "window.controlsStyle" =
          if config.wayland.windowManager.hyprland.enable then "hidden" else "native";
        "workbench.tree.indent" = 20;
        "workbench.startupEditor" = "none";
        "workbench.editor.empty.hint" = "hidden";
        "github.copilot.chat.commitMessageGeneration.instructions.text" = "...existing code...";
      };
      extensions = 
         with pkgs; [
          vscode-marketplace.bmalehorn.vscode-fish
          vscode-marketplace.budparr.language-hugo-vscode
          vscode-marketplace.catppuccin.catppuccin-vsc
          vscode-marketplace.davidanson.vscode-markdownlint
          vscode-marketplace.dhoeric.ansible-vault
          vscode-marketplace.docker.docker
          vscode-marketplace.eamodio.gitlens
          vscode-marketplace.esbenp.prettier-vscode
          vscode-marketplace.formulahendry.code-runner
          vscode-marketplace.foxundermoon.shell-format
          vscode-marketplace.github.codespaces
          vscode-marketplace.github.copilot
          vscode-marketplace.github.copilot-chat
          vscode-marketplace.github.vscode-github-actions
          vscode-marketplace.github.vscode-pull-request-github
#          vscode-marketplace.hashicorp.terraform
          vscode-marketplace.janisdd.vscode-edit-csv
          vscode-marketplace.jeff-hykin.better-dockerfile-syntax
          vscode-marketplace.jeff-hykin.better-shellscript-syntax
          vscode-marketplace.jnoortheen.nix-ide
          vscode-marketplace.mads-hartmann.bash-ide-vscode
          vscode-marketplace.mechatroner.rainbow-csv
          vscode-marketplace.meronz.manpages
          vscode-marketplace.mindaro-dev.file-downloader
          vscode-marketplace.moshfeu.compare-folders
          vscode-marketplace.ms-azuretools.vscode-containers
          vscode-marketplace.ms-azuretools.vscode-docker
          vscode-marketplace.ms-kubernetes-tools.vscode-kubernetes-tools
          vscode-marketplace.ms-python.debugpy
          vscode-marketplace.ms-python.python
          vscode-marketplace.ms-python.vscode-pylance
          vscode-marketplace.ms-python.vscode-python-envs
          vscode-marketplace.ms-toolsai.jupyter
          vscode-marketplace.ms-toolsai.jupyter-keymap
          vscode-marketplace.ms-toolsai.jupyter-renderers
          vscode-marketplace.ms-toolsai.vscode-jupyter-cell-tags
          vscode-marketplace.ms-toolsai.vscode-jupyter-slideshow
          vscode-marketplace.ms-vscode-remote.remote-containers
          vscode-marketplace.ms-vscode-remote.remote-ssh
          vscode-marketplace.ms-vscode-remote.remote-ssh-edit
          vscode-marketplace.ms-vscode-remote.remote-wsl
          vscode-marketplace.ms-vscode.powershell
          vscode-marketplace.ms-vscode.remote-explorer
          vscode-marketplace.pdconsec.vscode-print
          vscode-marketplace.redhat.ansible
          vscode-marketplace.redhat.vscode-commons
          vscode-marketplace.redhat.vscode-yaml
          vscode-marketplace.remisa.shellman
          vscode-marketplace.rogalmic.bash-debug
          vscode-marketplace.rusnasonov.vscode-hugo
          vscode-marketplace.ryu1kn.edit-with-shell
          vscode-marketplace.streetsidesoftware.code-spell-checker
          vscode-marketplace.tamasfe.even-better-toml
          vscode-marketplace.tetradresearch.vscode-h2o
          vscode-marketplace.timonwong.shellcheck
          vscode-marketplace.weaveworks.vscode-gitops-tools
          vscode-marketplace.woozy-masta.shell-script-ide
          vscode-marketplace.xshrim.txt-syntax
          vscode-marketplace.zainchen.json
          vscode-marketplace.aaron-bond.better-comments
          vscode-marketplace.alefragnani.project-manager
          vscode-marketplace.automatalabs.copilot-mcp
          vscode-marketplace.bmalehorn.shell-syntax
          vscode-marketplace.catppuccin.catppuccin-vsc-icons
          vscode-marketplace.codezombiech.gitignore
          vscode-marketplace.coolbear.systemd-unit-file
          vscode-marketplace.dotjoshjohnson.xml
          vscode-marketplace.editorconfig.editorconfig
          vscode-marketplace.eliostruyf.vscode-front-matter
          vscode-marketplace.evan-buss.font-switcher
          vscode-marketplace.fill-labs.dependi
          vscode-marketplace.griimick.vhs
          vscode-marketplace.hoovercj.vscode-power-mode
          vscode-marketplace.jeff-hykin.better-csv-syntax
          vscode-marketplace.jeff-hykin.better-nix-syntax
          vscode-marketplace.jeff-hykin.polacode-2019
          vscode-marketplace.jeroen-meijer.pubspec-assist
          vscode-marketplace.marp-team.marp-vscode
          vscode-marketplace.mkhl.direnv
          vscode-marketplace.ms-vscode.cmake-tools
          vscode-marketplace.ms-vscode.hexeditor
          vscode-extensions.ms-vscode-remote.vscode-remote-extensionpack
          vscode-marketplace.nefrob.vscode-just-syntax
          vscode-marketplace.nico-castell.linux-desktop-file
          vscode-marketplace.pixelbyte-studios.pixelbyte-love2d
          vscode-marketplace.pkief.material-product-icons
          vscode-marketplace.prince781.vala
          vscode-marketplace.pollywoggames.pico8-ls
          vscode-marketplace.rust-lang.rust-analyzer
          vscode-marketplace.ryu1kn.partial-diff
          vscode-marketplace.s3anmorrow.openwithkraken
          vscode-marketplace.sanjulaganepola.github-local-actions
          vscode-marketplace.slevesque.shader
          vscode-marketplace.trond-snekvik.simple-rst
          vscode-marketplace.twxs.cmake
          vscode-marketplace.tobiashochguertel.just-formatter
          vscode-marketplace.unifiedjs.vscode-mdx
          vscode-marketplace.viktorzetterstrom.non-breaking-space-highlighter
          vscode-marketplace.vscode-icons-team.vscode-icons
          vscode-marketplace.xyc.vscode-mdx-preview
          vscode-marketplace.yzhang.markdown-all-in-one
        ]
        ++ lib.optionals isLinux [
          vscode-extensions.ms-vscode.cpptools-extension-pack
          vscode-extensions.ms-vsliveshare.vsliveshare
          vscode-extensions.vadimcn.vscode-lldb
        ];
      
    };
    mutableExtensionsDir = true;
    package = pkgs.unstable.vscode;
  };
}


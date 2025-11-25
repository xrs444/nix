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
      extensions = ...existing code...;
    };
    mutableExtensionsDir = true;
    package = pkgs.unstable.vscode;
  };
  services.vscode-server.enable = true;
}

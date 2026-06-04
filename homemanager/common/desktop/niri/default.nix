{ pkgs, lib, ... }:
{
  imports = [ ./modes ];

  # Write mode fragment files — session wrappers symlink active-mode.kdl to one of these.
  # Add  include "~/.config/niri/active-mode.kdl"  to your ~/.config/niri/config.kdl once
  # to enable per-mode Niri overrides (keybinds, outputs, spawn-at-startup).
  xdg.configFile = {
    "niri/modes/base.kdl".text = "// base mode — no overrides\n";
    "niri/modes/obs.kdl".text = ''
      // OBS mode — add Niri overrides here (spawn-at-startup, output config, keybinds)
      // Example: spawn-at-startup "obs"
    '';
    "niri/modes/llm.kdl".text = ''
      // LLM mode — add Niri overrides here
    '';
  };

  # Ensure active-mode.kdl exists on first HM activation so niri's include directive
  # doesn't fail before the first session wrapper has run.
  home.activation.initNiriActiveMode = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target="$HOME/.config/niri/active-mode.kdl"
    base="$HOME/.config/niri/modes/base.kdl"
    if [ ! -e "$target" ] && [ -e "$base" ]; then
      ln -sfn "$base" "$target"
    fi
  '';

  # One-shot service that fires after the graphical session starts and activates the
  # mode target that matches WOLF_MODE (imported into the user service manager by
  # niri-session-fixed before niri launches).
  systemd.user.services.mode-activate = {
    Unit = {
      Description = "Activate workflow mode target from WOLF_MODE";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'mode=\"\${WOLF_MODE:-base}\"; systemctl --user start \"mode-\${mode}.target\"'";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

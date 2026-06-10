{ pkgs, lib, ... }:
{
  imports = [ ./modes ];

  xdg.configFile = {
    "niri/config.kdl" = {
      force = true;
      text = ''
        input {
            keyboard {
                xkb {
                    layout "gb"
                }
            }
            touchpad {
                tap
                natural-scroll
            }
        }

        environment {
            QT_QPA_PLATFORM "wayland"
        }

        spawn-at-startup "noctalia-shell"

        // Per-mode overrides (keybinds, outputs, spawn-at-startup)
        include "~/.config/niri/active-mode.kdl"

      binds {
          // Applications
          Mod+T { spawn "foot"; }
          Mod+D { spawn "fuzzel"; }

          // Window management
          Mod+Q { close-window; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }

          // Focus — vim-style
          Mod+H { focus-column-left; }
          Mod+L { focus-column-right; }
          Mod+J { focus-window-or-workspace-down; }
          Mod+K { focus-window-or-workspace-up; }

          // Move windows
          Mod+Shift+H { move-column-left; }
          Mod+Shift+L { move-column-right; }
          Mod+Shift+J { move-window-down-or-to-workspace-down; }
          Mod+Shift+K { move-window-up-or-to-workspace-up; }

          // Workspaces
          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+Shift+1 { move-window-to-workspace 1; }
          Mod+Shift+2 { move-window-to-workspace 2; }
          Mod+Shift+3 { move-window-to-workspace 3; }
          Mod+Shift+4 { move-window-to-workspace 4; }
          Mod+Shift+5 { move-window-to-workspace 5; }

          // Screenshots
          Print { screenshot; }
          Ctrl+Print { screenshot-screen; }
          Alt+Print { screenshot-window; }

          // Session
          Mod+Shift+E { quit; }
          Mod+Shift+Slash { show-hotkey-overlay; }
      }
    '';
    };

    # Mode fragment files — session wrappers symlink active-mode.kdl to one of these.
    "niri/modes/base.kdl" = { force = true; text = "// base mode — no overrides\n"; };
    "niri/modes/obs.kdl" = {
      force = true;
      text = ''
        // OBS mode — add Niri overrides here (spawn-at-startup, output config, keybinds)
        // Example: spawn-at-startup "obs"
      '';
    };
    "niri/modes/llm.kdl" = {
      force = true;
      text = ''
        // LLM mode — add Niri overrides here
      '';
    };
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

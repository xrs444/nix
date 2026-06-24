{ lib, ... }:
{
  xdg.configFile."niri/config.kdl" = {
    force = true;
    text = ''
      input {
          keyboard {
              xkb {
                  layout "us"
              }
          }
          touchpad {
              tap
              natural-scroll
          }
      }

      environment {
          QT_QPA_PLATFORM "wayland"
          NOCTALIA_PAM_SERVICE "swaylock"
      }

      spawn-at-startup "noctalia-shell"

      binds {
          Mod+T { spawn "foot"; }
          Mod+D { spawn "fuzzel"; }

          Mod+Q { close-window; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }

          Mod+H { focus-column-left; }
          Mod+L { focus-column-right; }
          Mod+J { focus-window-or-workspace-down; }
          Mod+K { focus-window-or-workspace-up; }

          Mod+Shift+H { move-column-left; }
          Mod+Shift+L { move-column-right; }
          Mod+Shift+J { move-window-down-or-to-workspace-down; }
          Mod+Shift+K { move-window-up-or-to-workspace-up; }

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

          Print { screenshot; }
          Ctrl+Print { screenshot-screen; }
          Alt+Print { screenshot-window; }

          Mod+Shift+E { quit; }
          Mod+Shift+Slash { show-hotkey-overlay; }
      }
    '';
  };
}

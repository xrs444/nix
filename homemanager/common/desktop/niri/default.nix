{ pkgs, lib, ... }:
{
  imports = [ ./modes ];

  home.packages = [ pkgs.swww ];

  # Wallpaper daemon — runs for the lifetime of the graphical session.
  # Mode-specific wallpaper services (in modes/) depend on this and call `swww img`.
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "swww wallpaper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile = {
    "niri/config.kdl" = {
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
            // Tell noctalia-shell to use the swaylock PAM service for the lock screen.
            // Without this it auto-detects "login", which works but "swaylock" is the
            // purpose-built Wayland locker service and avoids subtle pam_unix differences.
            NOCTALIA_PAM_SERVICE "swaylock"
        }

        spawn-at-startup "noctalia-shell"

        // Monitor layout (xdt1-t). Positions are in logical pixels.
        // DP-1: 1600x1200 scale 1.0 → logical 1600×1200
        // DP-5: 4K portrait (2160×3840 after 270° rotation) scale 1.5 → logical 1440×2560
        // DP-6: 4K landscape scale 1.5 → logical 2560×1440
        // HDMI-A-2: 1920×1080 scale 1.0 → logical 1920×1080
        output "DP-1" {
            // Far left — 1600×1200, top edge aligns with DP-5
            position x=0 y=0
            transform "normal"
        }
        output "DP-5" {
            // Centre — 4K portrait; x = DP-1 logical width (1600)
            position x=1600 y=0
            transform "270"
            scale 1.5
        }
        output "DP-6" {
            // Far right — 4K landscape, centred on DP-5
            // x = 1600 + DP-5 logical width (2160/1.5 = 1440) = 3040
            // y = (DP-5 logical height − DP-6 logical height) / 2 = (2560 − 1440) / 2 = 560
            position x=3040 y=560
            transform "normal"
            scale 1.5
        }
        output "HDMI-A-2" {
            // OBS output — below DP-1, bottom edge aligns with DP-5
            // y = DP-5 logical height − HDMI-A-2 logical height = 2560 − 1080 = 1480
            position x=0 y=1480
            transform "normal"
        }

        // Per-mode overrides (keybinds, outputs, spawn-at-startup)
        include "~/.config/niri/active-mode.kdl"

        // Dual-GPU: NVIDIA is primary. Force rendering on NVIDIA so outputs on
        // renderD129 get direct local rendering instead of a cross-GPU copy that
        // lacks implicit sync, which causes corruption on NVIDIA screens.
        debug {
            render-drm-device "/dev/dri/renderD129"
        }

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
    "niri/modes/base.kdl" = {
      force = true;
      text = ''
        // base mode
        output "HDMI-A-2" {
            off
        }
      '';
    };
    "niri/modes/obs.kdl" = {
      force = true;
      text = ''
        // OBS mode — HDMI-A-2 reserved for OBS Fullscreen Projector (Preview)
        window-rule {
            match app-id="com.obsproject.Studio"
            match title="Fullscreen Projector"
            open-on-output "HDMI-A-2"
            open-fullscreen true
            open-focused false
        }
      '';
    };
    "niri/modes/llm.kdl" = {
      force = true;
      text = ''
        // LLM mode
        output "HDMI-A-2" {
            off
        }
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

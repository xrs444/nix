{ pkgs, lib, ... }:
let
  # Single source of truth for workflow modes: the fuzzel menu label, and any
  # units to stop while the mode is active (restarted again on switch-away).
  modes = {
    base = {
      label = "Base";
      suspend = [ ];
    };
    obs = {
      label = "OBS";
      suspend = [ ];
    };
    llm = {
      label = "LLM";
      suspend = [ ];
    };
    gaming = {
      label = "Gaming";
      suspend = [
        "syncthing.service"
        "voxtype.service"
        "sync-vikunja-tasks.timer"
      ];
    };
  };

  modeNames = lib.attrNames modes;

  labelCase = lib.concatMapStringsSep "\n" (name: ''
    ${name}) echo "${modes.${name}.label}" ;;
  '') modeNames;

  suspendCase = lib.concatMapStringsSep "\n" (name: ''
    ${name}) echo "${lib.concatStringsSep " " modes.${name}.suspend}" ;;
  '') modeNames;

  labelToNameCase = lib.concatMapStringsSep "\n" (name: ''
    "${modes.${name}.label}") echo "${name}" ;;
  '') modeNames;

  wolfMode = pkgs.writeShellApplication {
    name = "wolf-mode";
    runtimeInputs = with pkgs; [
      fuzzel
      libnotify
      systemd
      coreutils
    ];
    text = ''
      state_dir="$HOME/.local/state/niri"
      state_file="$state_dir/wolf-mode"
      active_kdl="$HOME/.config/niri/active-mode.kdl"
      modes_dir="$HOME/.config/niri/modes"

      mode_label() {
        case "$1" in
        ${labelCase}
        *) echo "$1" ;;
        esac
      }

      mode_suspend_units() {
        case "$1" in
        ${suspendCase}
        *) echo "" ;;
        esac
      }

      name_from_label() {
        case "$1" in
        ${labelToNameCase}
        *) return 1 ;;
        esac
      }

      current_mode() {
        if [ -f "$state_file" ]; then
          cat "$state_file"
        else
          echo "base"
        fi
      }

      apply_kdl() {
        mkdir -p "$state_dir"
        install -m644 "$modes_dir/$1.kdl" "$active_kdl"
      }

      switch_mode() {
        local new="$1" old new_suspend unit
        old="$(current_mode)"

        if [ "$new" = "$old" ]; then
          return 0
        fi

        systemctl --user stop "mode-''${old}.target" || true

        # Restart anything the old mode suspended that the new mode doesn't also suspend.
        new_suspend="$(mode_suspend_units "$new")"
        for unit in $(mode_suspend_units "$old"); do
          case " $new_suspend " in
          *" $unit "*) ;;
          *) systemctl --user start "$unit" || true ;;
          esac
        done

        apply_kdl "$new"

        for unit in $new_suspend; do
          systemctl --user stop "$unit" || true
        done

        echo "$new" > "$state_file"
        systemctl --user start "mode-''${new}.target"
        notify-send "Workflow mode" "$(mode_label "$new")" || true
      }

      cmd="''${1:-menu}"
      case "$cmd" in
      menu)
        labels="$(for m in ${lib.concatStringsSep " " modeNames}; do mode_label "$m"; done)"
        chosen="$(printf '%s\n' "$labels" | fuzzel --dmenu --prompt "Mode: ")"
        [ -n "$chosen" ] || exit 0
        target="$(name_from_label "$chosen")"
        switch_mode "$target"
        ;;
      switch)
        if [ $# -lt 2 ]; then
          echo "usage: wolf-mode switch <mode>" >&2
          exit 1
        fi
        switch_mode "$2"
        ;;
      current)
        current_mode
        ;;
      restore)
        mode="$(current_mode)"
        apply_kdl "$mode"
        systemctl --user start "mode-''${mode}.target"
        for unit in $(mode_suspend_units "$mode"); do
          systemctl --user stop "$unit" || true
        done
        ;;
      *)
        echo "usage: wolf-mode {menu|switch <mode>|current|restore}" >&2
        exit 1
        ;;
      esac
    '';
  };
in
{
  home.packages = [ wolfMode ];
}

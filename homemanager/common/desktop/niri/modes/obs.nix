{ pkgs, ... }:
let
  hdmiGuard = pkgs.writeShellScript "obs-hdmi-guard" ''
    TARGET_OUTPUT="HDMI-A-2"
    OBS_APP_ID="com.obsproject.Studio"

    until [ -S "$NIRI_SOCKET" ]; do sleep 0.5; done

    ${pkgs.niri}/bin/niri msg event-stream | \
    while IFS= read -r line; do
      key=$(printf '%s' "$line" | ${pkgs.jq}/bin/jq -r 'keys[0]' 2>/dev/null) || continue
      [ "$key" = "WindowOpenedOrChanged" ] || continue

      app_id=$(printf '%s' "$line" | ${pkgs.jq}/bin/jq -r '.WindowOpenedOrChanged.window.app_id // ""')
      ws_id=$(printf '%s' "$line" | ${pkgs.jq}/bin/jq -r '.WindowOpenedOrChanged.window.workspace_id // empty' 2>/dev/null)
      win_id=$(printf '%s' "$line" | ${pkgs.jq}/bin/jq -r '.WindowOpenedOrChanged.window.id')

      [ "$app_id" = "$OBS_APP_ID" ] && continue
      [ -z "$ws_id" ] && continue

      on_hdmi=$(${pkgs.niri}/bin/niri msg --json workspaces 2>/dev/null | \
        ${pkgs.jq}/bin/jq -r --argjson id "$ws_id" --arg out "$TARGET_OUTPUT" \
        '.[] | select(.id == $id and .output == $out) | .id' 2>/dev/null)
      [ -z "$on_hdmi" ] && continue

      ${pkgs.niri}/bin/niri msg action focus-window --id "$win_id" 2>/dev/null
      sleep 0.1
      ${pkgs.niri}/bin/niri msg action move-column-to-workspace 1 2>/dev/null
    done
  '';
in
{
  systemd.user.targets.mode-obs = {
    Unit.Description = "OBS streaming mode";
  };

  systemd.user.services.obs-studio = {
    Unit = {
      Description = "OBS Studio";
      After = [ "graphical-session.target" ];
      PartOf = [ "mode-obs.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.obs-studio}/bin/obs";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "mode-obs.target" ];
  };

  systemd.user.services.obs-hdmi-guard = {
    Unit = {
      Description = "Evict non-OBS windows from HDMI-A-2";
      After = [ "graphical-session.target" ];
      PartOf = [ "mode-obs.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${hdmiGuard}";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [ "NIRI_SOCKET=/run/user/%U/niri/socket" ];
    };
    Install.WantedBy = [ "mode-obs.target" ];
  };
}

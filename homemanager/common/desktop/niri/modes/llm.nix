{ pkgs, ... }:
let
  setWallpaper = pkgs.writeShellScript "wallpaper-llm" ''
    for ext in jpg jpeg png; do
      img="$HOME/.config/niri/wallpapers/llm.$ext"
      if [ -f "$img" ]; then
        ${pkgs.swww}/bin/swww img "$img" --transition-type grow --transition-pos 0.5,0.5
        exit 0
      fi
    done
  '';
in
{
  systemd.user.targets.mode-llm = {
    Unit.Description = "LLM / AI work mode";
  };

  # Place ~/.config/niri/wallpapers/llm.{jpg,jpeg,png} for this to take effect.
  systemd.user.services.wallpaper-llm = {
    Unit = {
      Description = "Set wallpaper for LLM mode";
      After = [ "graphical-session.target" "swww-daemon.service" ];
      Requires = [ "swww-daemon.service" ];
      PartOf = [ "mode-llm.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setWallpaper}";
    };
    Install.WantedBy = [ "mode-llm.target" ];
  };
}

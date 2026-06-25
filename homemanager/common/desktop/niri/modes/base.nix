{ pkgs, ... }:
let
  setWallpaper = pkgs.writeShellScript "wallpaper-base" ''
    for ext in jpg jpeg png; do
      img="$HOME/.config/niri/wallpapers/base.$ext"
      if [ -f "$img" ]; then
        ${pkgs.swww}/bin/swww img "$img" --transition-type grow --transition-pos 0.5,0.5
        exit 0
      fi
    done
  '';
in
{
  systemd.user.targets.mode-base = {
    Unit.Description = "Base Niri mode (no autostart)";
  };

  # Place ~/.config/niri/wallpapers/base.{jpg,jpeg,png} for this to take effect.
  systemd.user.services.wallpaper-base = {
    Unit = {
      Description = "Set wallpaper for base mode";
      After = [ "graphical-session.target" "swww-daemon.service" ];
      Requires = [ "swww-daemon.service" ];
      PartOf = [ "mode-base.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setWallpaper}";
    };
    Install.WantedBy = [ "mode-base.target" ];
  };
}

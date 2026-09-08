{ pkgs, ... }:
let
  setWallpaper = pkgs.writeShellScript "wallpaper-gaming" ''
    for ext in jpg jpeg png; do
      img="$HOME/.config/niri/wallpapers/gaming.$ext"
      if [ -f "$img" ]; then
        ${pkgs.swww}/bin/swww img "$img" --transition-type grow --transition-pos 0.5,0.5
        exit 0
      fi
    done
  '';
in
{
  systemd.user.targets.mode-gaming = {
    Unit.Description = "Gaming mode (background services suspended)";
  };

  # Place ~/.config/niri/wallpapers/gaming.{jpg,jpeg,png} for this to take effect.
  systemd.user.services.wallpaper-gaming = {
    Unit = {
      Description = "Set wallpaper for gaming mode";
      After = [ "graphical-session.target" "swww-daemon.service" ];
      Requires = [ "swww-daemon.service" ];
      PartOf = [ "mode-gaming.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setWallpaper}";
    };
    Install.WantedBy = [ "mode-gaming.target" ];
  };
}

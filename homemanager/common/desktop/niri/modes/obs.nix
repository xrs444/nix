{ pkgs, ... }:
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
}

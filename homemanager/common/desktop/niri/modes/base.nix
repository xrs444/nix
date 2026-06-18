{ ... }:
{
  systemd.user.targets.mode-base = {
    Unit.Description = "Base Niri mode (no autostart)";
  };
}

# Common performance settings for NixOS hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Compressed RAM-based swap to prevent OOM kills under memory pressure
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # CPU frequency governor for performance
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  # Disable automatic sleep/suspend
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # Prevent logind from suspending on idle or lid close
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      IdleAction = "ignore";
    };
  };
}

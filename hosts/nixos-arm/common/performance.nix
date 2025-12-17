# Common performance settings for NixOS ARM hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # CPU frequency governor - ARM systems often benefit from ondemand or schedutil
  # for better power efficiency, but performance can be used for servers
  # Use very low priority to avoid conflicts with null defaults
  powerManagement.cpuFreqGovernor = lib.mkOverride 2000 "ondemand";

  # Enable zswap for better memory management on ARM systems with limited RAM
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    memoryPercent = lib.mkDefault 25;
  };

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

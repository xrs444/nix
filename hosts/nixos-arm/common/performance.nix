# Common performance settings for NixOS ARM hosts
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # IP forwarding — required for Tailscale exit node / subnet router / iprouting
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # ethtool offload settings recommended by Tailscale for exit nodes (kernel 6.2+, Tailscale 1.54+)
  # Dynamically detects the default-route interface so this works across both xts1 (end0) and xts2
  systemd.services.tailscale-ethtool = {
    description = "Configure ethtool offloads for Tailscale performance";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      NETDEV=$(${pkgs.iproute2}/bin/ip -o route get 8.8.8.8 | cut -f 5 -d " ")
      ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
    '';
  };
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

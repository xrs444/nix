{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
let
  tsClients = [ "xsvr1" "xsvr2" "xsvr3" "xtl1-t-nixos"];
  tsExitNodes = [ "xts1" "xts2" ];

in
{
  config = lib.mkMerge [
    (lib.mkIf (lib.elem "${hostname}" tsClients) {
      environment.systemPackages = with pkgs; lib.optionals isWorkstation [ trayscale ];
      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--operator=${username} --accept-routes"
        ];
        extraSetFlags = [
          "--operator=${username} --accept-routes"
        ];
      };
    })

    (lib.mkIf (lib.elem "${hostname}" tsExitNodes) {

      environment.systemPackages = with pkgs ; [
        ethtool
        networkd-dispatcher
        keepalived
      ];

      services.tailscale = {
        enable = true;

          extraUpFlags = [
            "--advertise-exit-node"
            "--accept-routes"
            "--advertise-routes=172.16.0.0/12"
            "--snat-subnet-routes=false"
          ];
          openFirewall = true;
          useRoutingFeatures = "both";
      };
      networking.firewall.checkReversePath = "loose";

      services.networkd-dispatcher = {
        enable = true;
        rules."99-tailscale" = {
          onState = [ "routable" ];
          script = ''
            #!/bin/sh
            NIC=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')
            ethtool -K "$NIC" rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };

      services.keepalived = {
        enable = true;
        vrrpInstances = {
          ts-vip = {
            interface = "eth0";
            virtualRouterId = 51;
            priority = if hostname == "xts1" then 101 else if hostname == "xts2" then 100 else 99;
            state = if hostname == "xts1" then "MASTER" else "BACKUP";
            virtualIps = [
              { addr = "172.18.10.100/24"; }
            ];
          };
        };
      };
    })
  ];
}

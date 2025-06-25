{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  ...
}:
let
  tsClients = [
  ];
  tsExitNodes = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
  ];

in
{
  config = lib.mkMerge [
    
    ( lib.mkIf (lib.elem "${hostname}" tsClients) {

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
    ( lib.mkIf (lib.elem "${hostname}" tsExitNodes) {
     
      containers.nextcloud = {
        autoStart = true;
        hostName = "${hostname}-ts";
        privateNetwork = false;
        bridge = "bridge21";
        config = { config, pkgs, lib, ... }: {

          environment.systemPackages = with pkgs; [
            tailscale
            ethtool
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
            script = ''
              #!/bin/sh
              ethtool -K bond0 rx-udp-gro-forwarding on rx-gro-list off
            '';
          };

          system.stateVersion = "25.05";

          networking = {
            useDHCP = true;
            firewall = {
              enable = false;
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;
        };
      };
    })
  ]
}






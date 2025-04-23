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
    "xsvr1"
    "xsvr2"
  ];
  tsExitNodes = [
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
     
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;  
      environment.systemPackages = with pkgs; [ 
        tailscale
        ethtool
        networkd-dispatcher
      ];

      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--operator=${username} --advertise-exit-node --accept-routes"
          ];
        extraSetFlags = [
          "--operator=${username} --advertise-exit-node --accept-routes"
          ];
        openFirewall = true;
        useRoutingFeatures = "server";
        interfaceName = "userspace-networking";
        };
        networking.firewall.checkReversePath = "loose";
      services.networkd-dispatcher = {
        enable = true;
        rules."50-tailscale" = {
        onState = ["routable"];
        script = ''
          "${pkgs.ethtool} NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ") | -K enp5s0 rx-udp-gro-forwarding on rx-gro-list off
          '';
         };
      };  
    })
  ];
}

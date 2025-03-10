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
  tsExitnodes = [
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
          "--operator=${username}"
        ];
        extraSetFlags = [
          "--operator=${username}"
        ];
      };     
    })   
    ( lib.mkIf (lib.elem "${hostname}" tsExitNodes) {
     
      environment.systemPackages = with pkgs; [ 
        ethtool
        networkd-dispatcher
      ];

      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--operator=${username} --advertise-exit-node"
          ];
        extraSetFlags = [
          "--operator=${username} --advertise-exit-node"
          ];
        openFirewall = true;
        useRoutingFeatures = "both";
        interfaceName = "userspace-networking";
        };
     
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
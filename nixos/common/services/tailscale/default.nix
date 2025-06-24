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
     
      boot.kernel = {
        sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
        sysctl."net.ipv6.conf.all.forwarding" = lib.mkForce 1;
      };  
      environment.systemPackages = with pkgs; [ 
        tailscale
      ];

      services.tailscale = {
        enable = true;
        extraUpFlags = [
#          "--operator=${username}"
          "--advertise-exit-node"
          "--accept-routes"
          "--allow-lan-access"
          "--advertise-routes=172.16.0.0/12"
          "--snat-subnet-routes=false"
          ];
        openFirewall = true;
        useRoutingFeatures = "both";
        };
      networking.firewall.checkReversePath = "loose";
    })
  ];
}

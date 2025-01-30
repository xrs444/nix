{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
  ];
  k3s-firstnode = [
    "xsvr1"
  ];
  k3s-node = [
    "xsvr2"
    "xsvr3"
  ];
in
{
  config = lib.mkMerge [
    
    ( lib.mkIf (lib.elem "${hostname}" installOn) {
     
      services.k3s = {
      # enable = true;
        role = "server";
        token = "<randomized common secret>";
        gracefulNodeShutdown = {
          enable = true;
          shutdownGracePeriod = "3m"
          };
      };

      services.openiscsi = {
        enable = true;
        name = "iqn.2005-10.nixos:${config.networking.hostName}";
      };
        
      environment.systemPackages = with pkgs; [
        fluxcd
        kubectl
        kubecolor
        nfs-utils
        openiscsi
      ];
        
      networking.firewall.allowedTCPPorts = [
        6443 # k3s API
        2379 # k3s etcd clients
        2380 # k3s etcd peers
      ];
      networking.firewall.allowedUDPPorts = [
        8472 # flannel
      ];
    
    } )  
    
    ( lib.mkIf (lib.elem "${hostname}" k3s-firstnode) {
     
      services.k3s = {
        clusterInit = true;
        extraFlags = toString [
          "--disable traefik --disable servicelb --cluster-domain 'xrs444.net'"
        ];
    };
    
    } )
    
    ( lib.mkIf (lib.elem "${hostname}" k3s-node) {
     
      services.k3s = {
        serverAddr =  "https://172.20.1.10:6443";
      };
    } )
  ];
}

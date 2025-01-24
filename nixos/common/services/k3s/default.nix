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

  config = lib.mkMerge [
    
    ( lib.mkIf (lib.elem "${hostname}" installOn) {
     
      services.k3s = {
      # enable = true;
        role = "server";
        token = "<randomized common secret>";
      };
        
      environment.systemPackages = with pkgs; [
        fluxcd
        kubectl
        kubecolor
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
     
      clusterInit = true;
      extraFlags = toString [
        "--disable traefik --disable servicelb" 
      ];
    
    } )
    
    ( lib.mkIf (lib.elem "${hostname}" k3s-node) {
    
      serverAddr =  "https://172.20.1.10:6443";

    } )
  ];
in
  config.contents

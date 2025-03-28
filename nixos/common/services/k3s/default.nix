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
     
      sops.secrets."k3s_token" = {
        sopsFile = ../../../../secrets/k3s.yaml;
        format = "yaml";
        owner = "root";
        group = "root";
        mode = "0600";
        path = "/etc/k3s/token";
      };

      services.k3s = {
        enable = true;
        role = "server";
        tokenFile = config.sops.secrets."k3s_token".path;
        gracefulNodeShutdown = {
          enable = true;
          shutdownGracePeriod = "3m";
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
          "--disable traefik --disable servicelb --cluster-domain 'xrs444.net'--cluster-cidr=172.21.0.0/16 --service-cidr=172.22.0.0/16 --flannel-iface=bond0"
        ];
    };
    
    } )
    
    ( lib.mkIf (lib.elem "${hostname}" k3s-node) {
     
      services.k3s = {
        serverAddr =  "https://172.20.1.10:6443";
        extraFlags = toString [
          "--disable servicelb --flannel-iface=bond0"
        ];
      };
    } )
  ];
}


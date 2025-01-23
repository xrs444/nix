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
lib.mkIf (lib.elem "${hostname}" installOn) {

  services.k3s = {
#    enable = true;
    role = "server";
    token = "<randomized common secret>";
    clusterInit = [] ++ lib.optional (lib.elem "${hostname}" k3s-firstnode) true;
    serverAddr = [] ++ lib.optional (lib.elem "${hostname}" k3s-node) "https://172.20.1.10:6443";
    extraFlags = toString [
    "--disable traefik --disable servicelb"
    ];
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
}

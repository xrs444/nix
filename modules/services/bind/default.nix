# Summary: NixOS module for Bind DNS service, serves lab.xrs444.net zone authoritatively.
{
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:

let
  hasRole = lib.elem "bind" hostRoles;
in
{
  config = lib.mkIf hasRole {

    # Open DNS port in firewall
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.bind = {
      enable = true;
      # Temporarily listen on all IPs for troubleshooting
      # listenOn = lib.mkIf hasDedicatedDnsIP [ dnsIP ];
      # listenOnIpv6 = lib.mkIf hasDedicatedDnsIP [ ];
      zones = {
        "lab.xrs444.net" = {
          master = true;
          file = pkgs.writeText "lab_xrs444_net" ''
            $ORIGIN lab.xrs444.net.
            $TTL    1h
            @            IN      SOA     ns1 hostmaster (
                                             1    ; Serial
                                             3h   ; Refresh
                                             1h   ; Retry
                                             1w   ; Expire
                                             1h)  ; Negative Cache TTL
                         IN      NS      ns1

            @                 IN      A       172.25.2.251

            ns1               IN      A       172.25.2.251

            xlabmgmt          IN      A       172.25.2.251

            xntnx1            IN      A       172.25.1.10

            xntnx2            IN      A       172.25.1.20

            xntnx3            IN      A       172.25.1.30

            ntnx-xntnx1-cvm   IN      A       172.25.1.11

            ntnx-xntnx2-cvm   IN      A       172.25.1.21

            ntnx-xntnx3-cvm   IN      A       172.25.1.31

            xntnx-pc          IN      A       172.25.2.100
          '';
        };
      };
    };
  };
}

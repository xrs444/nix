# Summary: NixOS module for Bind DNS service, enables and configures DNS forwarding for specified hosts.
{
  config,
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  platform,
  ...
}:

let
  hasRole = lib.elem "bind" hostRoles;
in
{
  config = lib.mkIf hasRole {

    services.bind = {
      enable = true;
      forwarders = [ "172.18.11.250" ];
      cacheNetworks = [
        "172.16.0.0/12"
        "100.64.0.0/10"
      ];
      zones = {
        "lab.xrs444.net" = {
          master = true;
          file = pkgs.writeText "lab_xrs444_net" ''
            $ORIGIN example.com.
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

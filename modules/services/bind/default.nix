# Summary: NixOS module for Bind DNS service, enables and configures DNS forwarding for specified hosts.
{
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:

let
  hasRole = lib.elem "bind" hostRoles;

  # Host-specific DNS IP configuration (only for xsvr1 and xsvr2)
  # Using macvlan interfaces with unique MAC addresses for Firewalla registration
  hasDedicatedDnsIP = hostname == "xsvr1" || hostname == "xsvr2";
  dnsIP =
    if hostname == "xsvr1" then
      "172.18.10.10"
    else if hostname == "xsvr2" then
      "172.18.10.20"
    else
      null;
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
      forward = "first"; # Forward to these servers first, use root hints as fallback
      forwarders = [ "1.1.1.1" "9.9.9.9" ];
      # Temporarily allow all RFC1918 networks for DNS troubleshooting
      cacheNetworks = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
      ];
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
      extraConfig = ''
        # Conditional forwarder for Tailscale domain
        zone "corgi-squeaker.ts.net" {
          type forward;
          forward only;
          forwarders { 100.100.100.100; };
        };

        # Authoritative zone for xrs444.net
        zone "xrs444.net" {
          type master;
          file "${pkgs.writeText "xrs444_net" ''
            $ORIGIN xrs444.net.
            $TTL    1h
            @            IN      SOA     ns1 hostmaster (
                                             1    ; Serial
                                             3h   ; Refresh
                                             1h   ; Retry
                                             1w   ; Expire
                                             1h)  ; Negative Cache TTL
                         IN      NS      ns1

            ns1                IN      A       127.0.0.1

            ; Kubernetes applications via Traefik (172.21.0.2)
            apprise            IN      A       172.21.0.2
            atuin              IN      A       172.21.0.2
            audiobookshelf     IN      A       172.21.0.2
            booklore           IN      A       172.21.0.2
            borgwarehouse      IN      A       172.21.0.2
            cups               IN      A       172.21.0.2
            crafty             IN      A       172.21.0.2
            loki               IN      A       172.21.0.2
            element            IN      A       172.21.0.2
            garage             IN      A       172.21.0.2
            home               IN      A       172.21.0.2
            immich             IN      A       172.21.0.2
            jellyfin           IN      A       172.21.0.2
            jitsi              IN      A       172.21.0.2
            linkwarden         IN      A       172.21.0.2
            loki               IN      A       172.21.0.2
            longhorn           IN      A       172.21.0.2
            lubelogger         IN      A       172.21.0.2
            manyfold           IN      A       172.21.0.2
            matrix             IN      A       172.21.0.2
            mealie             IN      A       172.21.0.2
            netbox             IN      A       172.21.0.2
            nocodb             IN      A       172.21.0.2
            ntfy               IN      A       172.21.0.2
            paperless          IN      A       172.21.0.2
            romm               IN      A       172.21.0.2
            rustdesk           IN      A       172.21.0.2
            s3                 IN      A       172.21.0.2
            tdarr              IN      A       172.21.0.2
            traefik            IN      A       172.21.0.2
            synapse            IN      A       172.21.0.2
             ; Other services
            omada              IN      A       172.21.0.7
            nixcache           IN      A       172.20.1.10
            idm                IN      A       172.20.1.110
            xrs444-k8s.x       IN      A       172.20.3.100
            time               IN      A       172.18.10.250
             ; VMs and devices
            hass               IN      A       172.18.7.1
            pbx                IN      A       172.18.6.1
            cmrpi1             IN      A       192.168.0.10
            cmrnas             IN      A       192.168.0.11
            xsvr1              IN      A       172.20.1.10
            xsvr2              IN      A       172.20.1.20
            xsvr3              IN      A       172.20.1.30
          ''}";
        };
      '';
    };

    # Firewall rules to restrict DNS IP to only DNS traffic (only for dedicated DNS IPs)
    # TEMPORARILY DISABLED - ALL RULES COMMENTED OUT FOR DNS TROUBLESHOOTING
    networking.firewall.extraCommands = lib.mkIf hasDedicatedDnsIP ''
      # Allow incoming DNS queries on dedicated DNS IP
      # iptables -A nixos-fw -d ${dnsIP} -p udp --dport 53 -j ACCEPT
      # iptables -A nixos-fw -d ${dnsIP} -p tcp --dport 53 -j ACCEPT

      # Allow outgoing DNS queries to forwarders (1.1.1.1, 9.9.9.9, and 100.100.100.100)
      # iptables -A nixos-fw -s ${dnsIP} -d 1.1.1.1 -p udp --dport 53 -j ACCEPT
      # iptables -A nixos-fw -s ${dnsIP} -d 1.1.1.1 -p tcp --dport 53 -j ACCEPT
      # iptables -A nixos-fw -s ${dnsIP} -d 9.9.9.9 -p udp --dport 53 -j ACCEPT
      # iptables -A nixos-fw -s ${dnsIP} -d 9.9.9.9 -p tcp --dport 53 -j ACCEPT
      # iptables -A nixos-fw -s ${dnsIP} -d 100.100.100.100 -p udp --dport 53 -j ACCEPT
      # iptables -A nixos-fw -s ${dnsIP} -d 100.100.100.100 -p tcp --dport 53 -j ACCEPT

      # Block all other traffic to/from DNS IP
      # TEMPORARILY DISABLED FOR DNS TROUBLESHOOTING
      # iptables -A nixos-fw -d ${dnsIP} -j DROP
      # iptables -A nixos-fw -s ${dnsIP} -j DROP
    '';

    # TEMPORARILY DISABLED - ALL CLEANUP RULES COMMENTED OUT FOR DNS TROUBLESHOOTING
    networking.firewall.extraStopCommands = lib.mkIf hasDedicatedDnsIP ''
      # Cleanup rules when firewall is stopped
      # iptables -D nixos-fw -d ${dnsIP} -p udp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -d ${dnsIP} -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -d 1.1.1.1 -p udp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -d 1.1.1.1 -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -d 9.9.9.9 -p udp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -d 9.9.9.9 -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -d 100.100.100.100 -p udp --dport 53 -j ACCEPT 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -d 100.100.100.100 -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
      # TEMPORARILY DISABLED FOR DNS TROUBLESHOOTING
      # iptables -D nixos-fw -d ${dnsIP} -j DROP 2>/dev/null || true
      # iptables -D nixos-fw -s ${dnsIP} -j DROP 2>/dev/null || true
    '';
  };
}

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

# Summary: NixOS module for AdGuard Home DNS server and adguardhome-sync
{
  config,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  hasRole = lib.elem "adguard" hostRoles;
in
lib.mkIf hasRole {
  # Enable AdGuard Home
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        # Upstream DNS servers
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://cloudflare-dns.com/dns-query"
          "1.1.1.1"
          "9.9.9.9"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
      };
    };
  };

  # Install adguardhome-sync for syncing configuration
  environment.systemPackages = with pkgs; [
    # adguardhome-sync # Add when available in nixpkgs
  ];

  # Create systemd service for adguardhome-sync
  # This will sync AdGuard Home configuration to a backup instance
  systemd.services.adguardhome-sync = {
    description = "AdGuard Home Configuration Sync";
    after = [
      "network.target"
      "adguardhome.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      # Placeholder for sync command - configure with actual sync script
      # ExecStart = "${pkgs.adguardhome-sync}/bin/adguardhome-sync run";
    };
  };

  # Firewall rules for AdGuard Home (N4). DNS (53 tcp/udp) and the web UI (3000) used to be
  # open to every network. A listener can't bind to a CIDR, so the services still bind
  # 0.0.0.0 and the firewall restricts who may reach them: the local LAN, the 172.16/12
  # home VLANs, and the Tailscale range. Loopback is always allowed by the base firewall;
  # SSH is unaffected (separate rule in the openssh module).
  # IPv4 rules, plus the Tailscale ULA range for IPv6 clients on the tailnet. delete-then-add
  # keeps each rule idempotent across activations (see the keepalived module for why).
  networking.firewall.extraCommands =
    let
      v4Allowed = [
        "192.168.0.0/24"
        "172.16.0.0/12"
        "100.64.0.0/10"
      ];
      v4Rule = cidr: proto: port: ''
        iptables -D nixos-fw -s ${cidr} -p ${proto} --dport ${toString port} -j nixos-fw-accept 2>/dev/null || true
        iptables -A nixos-fw -s ${cidr} -p ${proto} --dport ${toString port} -j nixos-fw-accept
      '';
      v6Rule = proto: port: ''
        ip6tables -D nixos-fw -s fd7a:115c:a1e0::/48 -p ${proto} --dport ${toString port} -j nixos-fw-accept 2>/dev/null || true
        ip6tables -A nixos-fw -s fd7a:115c:a1e0::/48 -p ${proto} --dport ${toString port} -j nixos-fw-accept
      '';
      services = [
        {
          proto = "tcp";
          port = 53;
        }
        {
          proto = "udp";
          port = 53;
        }
        {
          proto = "tcp";
          port = 3000;
        }
      ];
    in
    lib.concatStringsSep "\n" (
      lib.concatMap (s: map (cidr: v4Rule cidr s.proto s.port) v4Allowed) services
      ++ map (s: v6Rule s.proto s.port) services
    );
}

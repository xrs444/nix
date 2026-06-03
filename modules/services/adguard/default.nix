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
    after = [ "network.target" "adguardhome.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      # Placeholder for sync command - configure with actual sync script
      # ExecStart = "${pkgs.adguardhome-sync}/bin/adguardhome-sync run";
    };
  };

  # Firewall rules for AdGuard Home
  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS
      3000 # AdGuard Home Web UI
    ];
    allowedUDPPorts = [
      53 # DNS
    ];
  };
}

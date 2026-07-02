# Summary: NixOS ARM host configuration for xts2, imports boot and disk modules.
# Boot: UEFI from SPI flash (LibreTech firmware). No U-Boot activation script needed.
{ hostname, lib, pkgs, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/boot.nix
    ../common/performance.nix
    ../common/hardware-sweet-potato.nix
    ./disks.nix
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;

  # Listening on tailscale0 allows DNS to also work when accessed via Tailscale IP.
  services.dnsmasq = {
    enable = true;
    settings = {
      server = [ "/ts.net/100.100.100.100" ];
      interface = [ "lo" "eth0" "tailscale0" ];
      # bind-dynamic: like bind-interfaces but picks up IPs added after startup
      # (keepalived VIP and tailscale0 both come up after dnsmasq starts)
      bind-dynamic = true;
      # Disable negative caching: at boot, dnsmasq starts before Bird installs
      # the 100.64.0.0/10 route via the Tailscale socket, so the first ts.net
      # forward fails. Without no-negcache, that NXDOMAIN is cached until restart.
      no-negcache = true;
    };
  };
  # Wait for Bird to install the 100.64.0.0/10 route via the Tailscale socket before
  # dnsmasq starts. Without this, the first ts.net forward to 100.100.100.100 fails
  # (no route), the Firewalla caches the NXDOMAIN, and all clients get NXDOMAIN until
  # the Firewalla is restarted.
  systemd.services.dnsmasq = {
    after = [ "tailscaled.service" "bird.service" ];
    preStart = lib.mkBefore ''
      echo "Waiting for Bird to install 100.64.0.0/10 via tailscale0..."
      for i in $(seq 30); do
        ${pkgs.iproute2}/bin/ip route show 100.64.0.0/10 | grep -q tailscale0 && break
        sleep 1
      done
    '';
  };
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [
    22  # SSH — local LAN access
    53  # DNS
  ];
}

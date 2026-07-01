# Summary: NixOS ARM host configuration for xts2, imports boot and disk modules.
# Boot: UEFI from SPI flash (LibreTech firmware). No U-Boot activation script needed.
{ hostname, ... }:
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
      bind-interfaces = true;
    };
  };
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [
    22  # SSH — local LAN access
    53  # DNS
  ];
}

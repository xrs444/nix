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

  services.dnsmasq = {
    enable = true;
    settings = {
      server = [ "/ts.net/100.100.100.100" ];
      listen-address = [ "127.0.0.1" "172.18.10.2" ];
      bind-interfaces = true;
    };
  };
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [
    22  # SSH — local LAN access
    53  # DNS
  ];
}

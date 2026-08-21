# Summary: NixOS ARM host configuration for xidm1 (Kanidm 3rd read-replica + last-resort
# idm VIP member), imports boot and disk modules.
# Boot: UEFI from SPI flash (LibreTech firmware). No U-Boot activation script needed.
# Formerly xts2 (Tailscale exit-node era) — renamed 2026-08-21 when repurposed as a
# Kanidm replica on the server VLAN. See kanidm-replace-xts2-with-xidm1 in cerebrum.md.
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

  networking.firewall.allowedTCPPorts = [
    22  # SSH — local LAN access
  ];
}

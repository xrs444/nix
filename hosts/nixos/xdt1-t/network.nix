{ lib, ... }:
{
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # Wired NIC: enp8s0  |  WiFi NIC: wlp7s0  (confirmed from installer 2026-06-08)
}

{ lib, ... }:
{
  # Laptop — WiFi is the primary connection. NetworkManager lets Samantha
  # connect/switch networks herself via GNOME's network settings.
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # WiFi NIC: wlp2s0 (confirmed from installer 2026-08-09)
}

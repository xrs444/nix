{ lib, ... }:
{
  # Laptop — WiFi is the primary connection. NetworkManager lets Samantha
  # connect/switch networks herself via GNOME's network settings.
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # WiFi NIC name (e.g. wlanX/wlpXsX) — confirm from the installer and note
  # it here once known, matching the convention on other hosts.
}

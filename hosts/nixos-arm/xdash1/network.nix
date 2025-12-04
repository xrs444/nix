{ config, pkgs, ... }:

{
  # Enable NetworkManager for wired and wireless (Wi-Fi) networking
  networking.networkmanager.enable = true;

  # Ensure your user is in the "networkmanager" group to control Wi-Fi (see modules/users/thomas-local.nix)

  # Declarative Wi-Fi connection using SOPS secret for SSID and PSK (single file)
  networking.networkmanager.ensureProfiles.profiles = {
    "wifi" = {
      connection.id = "wifi";
      connection.type = "802-11-wireless";
      "802-11-wireless".ssidFile = config.sops.secrets."wan-wifi".path;
      "802-11-wireless".mode = "infrastructure";
      "802-11-wireless-security"."key-mgmt" = "wpa-psk";
      "802-11-wireless-security".pskFile = config.sops.secrets."wan-wifi".path;
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # SOPS secret for Wi-Fi SSID and PSK (single file)
  sops.secrets."wan-wifi" = {
    sopsFile = ../../../secrets/wan-wifi.yaml;
  };
}

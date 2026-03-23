{ config, pkgs, ... }:

{
  # Enable NetworkManager for wired and wireless (Wi-Fi) networking
  networking.networkmanager.enable = true;

  # Ensure your user is in the "networkmanager" group to control Wi-Fi (see modules/users/thomas-local.nix)

  # Declarative Wi-Fi connection using SOPS secrets for SSID and PSK
  networking.networkmanager.ensureProfiles.profiles = {
    "wifi" = {
      connection.id = "wifi";
      connection.type = "802-11-wireless";
      "802-11-wireless".ssidFile = config.sops.secrets."wan-wifi-ssid".path;
      "802-11-wireless".mode = "infrastructure";
      "802-11-wireless-security"."key-mgmt" = "wpa-psk";
      "802-11-wireless-security".pskFile = config.sops.secrets."wan-wifi-psk".path;
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # SOPS secrets for Wi-Fi
  sops.secrets."wan-wifi-ssid" = {
    sopsFile = ../../../secrets/wan-wifi.yaml;
    key = "SSID";
  };

  sops.secrets."wan-wifi-psk" = {
    sopsFile = ../../../secrets/wan-wifi.yaml;
    key = "PSK";
  };
}

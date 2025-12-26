{ config, pkgs, ... }:

{
  # Enable NetworkManager for wired and wireless (Wi-Fi) networking
  networking.networkmanager.enable = true;

  # Ensure your user is in the "networkmanager" group to control Wi-Fi (see modules/users/thomas-local.nix)

  # SOPS secrets for Wi-Fi
  sops.secrets."wan-wifi-ssid" = {
    sopsFile = ./../../../secrets/wan-wifi.yaml;
    key = "SSID";
  };

  sops.secrets."wan-wifi-psk" = {
    sopsFile = ./../../../secrets/wan-wifi.yaml;
    key = "PSK";
  };
}

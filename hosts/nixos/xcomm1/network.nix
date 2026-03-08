{ config, pkgs, lib, ... }:

{
  # Enable NetworkManager for wired and wireless (Wi-Fi) networking
  networking.networkmanager.enable = true;

  # Disable firmware compression so kernel can load wifi firmware
  # The iwlwifi driver needs uncompressed .ucode files
  nixpkgs.overlays = [
    (self: super: {
      compressFirmware = lib.id;
    })
  ];

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

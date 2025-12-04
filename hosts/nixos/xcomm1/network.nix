{ config, pkgs, ... }:

let
  wifiSecrets =
    if builtins.pathExists (toString config.sops.secrets."wan-wifi".path) then
      builtins.fromJSON (builtins.readFile config.sops.secrets."wan-wifi".path)
    else
      {
        SSID = null;
        PSK = null;
      };
in
{
  # Enable NetworkManager for wired and wireless (Wi-Fi) networking
  networking.networkmanager.enable = true;

  # Ensure your user is in the "networkmanager" group to control Wi-Fi (see modules/users/thomas-local.nix)

  # SOPS secret for Wi-Fi
  sops.secrets."wan-wifi" = {
    sopsFile = toString ./../../../secrets/wan-wifi.yaml;
  };
}

{ pkgs, lib, platform, config, ... }:
{
  networking = {
    hostName = "xdash1";
    networkmanager.enable = false;
    
    wireless = {
      enable = true;
      # Point to a secrets file that will be managed by sops
      secretsFile = config.sops.templates.wireless-secrets.path;
      networks = {
        # Reference the network by name from the secrets file
        "ext:SSID" = {};
      };
    };
  };

  sops.secrets.wifi-ssid = {
    sopsFile = ../../../secrets/wan-wifi.yaml;
    key = "SSID";
  };
  
  sops.secrets.wifi-psk = {
    sopsFile = ../../../secrets/wan-wifi.yaml;
    key = "PSK";
  };

  # Create a template file in wpa_supplicant.conf format
  sops.templates.wireless-secrets = {
    content = ''
      network={
        ssid="${config.sops.placeholder.wifi-ssid}"
        psk="${config.sops.placeholder.wifi-psk}"
      }
    '';
    mode = "0600";
  };
}
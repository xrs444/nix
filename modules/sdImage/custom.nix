# Summary: NixOS minimal SD image/installer module for bootstrapping hosts with comin.
# This module creates minimal bootable images that configure networking, SSH, and comin,
# then pull the full configuration from the git repository.
{
  config,
  pkgs,
  lib,
  minimalImage ? false,
  hostname ? null,
  ...
}:

{
  config = lib.mkIf minimalImage {
    # Networking: enable DHCP and NetworkManager for provisioning (unless wireless is enabled)
    networking.useDHCP = lib.mkDefault true;
    networking.networkmanager.enable = lib.mkDefault (!config.networking.wireless.enable);

    # SSH for remote access during provisioning
    services.openssh.enable = lib.mkForce true;
    services.openssh.settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PubkeyAuthentication = lib.mkDefault true;
    };

    # Add authorized keys for thomas-local user
    users.users.thomas-local.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqIkfm1V7YPoB9h/6BhR6UIiZGLxVl0U/XqLGpO3N3d thomas-local@xrs444.net"
    ];

    # WiFi configuration (conditional based on networking.wireless.enable from host config)
    networking.wireless.secretsFile = lib.mkIf config.networking.wireless.enable (
      config.sops.secrets."wan-wifi".path
    );
    networking.wireless.networks = lib.mkIf config.networking.wireless.enable {
      # Network name is provided as wan_ssid in secrets file
      # pskRaw uses ext: prefix for wpa_supplicant's new secrets mechanism
      "@wan_ssid@" = {
        pskRaw = "ext:wan_psk";
      };
    };

    # SOPS secret for WiFi (only if WiFi enabled)
    sops.secrets."wan-wifi" = lib.mkIf config.networking.wireless.enable {
      sopsFile = ../../secrets/wan-wifi.yaml;
    };

    # Enable comin for automatic configuration deployment
    services.comin = {
      enable = lib.mkForce true;
      hostname = hostname;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/xrs444/nix.git";
          branches.main.name = "main";
        }
      ];
    };

    # Ensure comin restarts on failure (use mkDefault to allow override)
    systemd.services.comin.serviceConfig = {
      Restart = lib.mkDefault "always";
      RestartSec = lib.mkDefault 30;
    };

    # Minimal system packages for bootstrapping
    environment.systemPackages = with pkgs; [
      git
      vim
      htop
      curl
      wget
    ];

    # Disable documentation to save space
    documentation.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    # Disable X11 and desktop services for headless images
    services.xserver.enable = lib.mkDefault false;
  };
}

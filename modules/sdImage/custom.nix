# Summary: NixOS minimal SD image/installer module for bootstrapping new hosts.
# Creates minimal bootable images with networking, SSH, and the deploy user configured
# so the full config can be pushed immediately via deploy-rs from xsvr1.
#
# Bootstrap workflow:
#   1. Flash SD image, boot device
#   2. From xsvr1: deploy .#<host>
#   3. deploy-rs pushes full config; subsequent deploys handled by CI
{
  config,
  lib,
  minimalImage ? false,
  pkgs,
  ...
}:

{
  config = lib.mkIf minimalImage {
    # Networking: enable DHCP for provisioning. NetworkManager is opt-in per-host (set
    # networking.networkmanager.enable = true in the host's own network.nix, as cmrpi1 does)
    # rather than defaulted on here.
    # NOTE: do NOT derive this default from config.networking.wireless.enable — NetworkManager's
    # own module conditionally sets networking.wireless.enable = true internally whenever it's
    # active, which makes that a circular reference (infinite recursion) once evaluated either way.
    # It also drags in bluez -> libical, which currently forces a local aarch64 build that hits
    # the known Python 3.13 distutils/GIR failure (see cerebrum Do-Not-Repeat 2026-06-30) unless
    # that exact libical output happens to be cached upstream.
    networking.useDHCP = lib.mkDefault true;
    networking.networkmanager.enable = lib.mkDefault false;

    # SSH for remote access during provisioning
    services.openssh.enable = lib.mkForce true;
    services.openssh.settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PubkeyAuthentication = lib.mkDefault true;
    };

    # Add authorized keys for thomas-local user (manual access / emergency)
    users.users.thomas-local.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqIkfm1V7YPoB9h/6BhR6UIiZGLxVl0U/XqLGpO3N3d thomas-local@xrs444.net"
    ];

    # Deploy user on minimal images so deploy-rs can push the full config immediately
    # after first boot without any manual SSH steps.
    users.groups.deploy = { };
    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      home = "/var/lib/deploy";
      createHome = true;
      shell = "/run/current-system/sw/bin/bash";
      openssh.authorizedKeys.keyFiles = [ ../../secrets/deploy_key.pub ];
    };
    security.sudo.extraConfig = ''
      deploy ALL=(root) NOPASSWD: /nix/store/*/activate-rs *
    '';

    # WiFi configuration via NetworkManager (conditional based on networking.wireless.enable from host config)
    networking.networkmanager.ensureProfiles.profiles = lib.mkIf config.networking.wireless.enable {
      "wifi" = {
        connection.id = "wifi";
        connection.type = "802-11-wireless";
        "802-11-wireless".mode = "infrastructure";
        "802-11-wireless".ssid = config.sops.secrets."wan-wifi-ssid".path;
        "802-11-wireless-security"."key-mgmt" = "wpa-psk";
        "802-11-wireless-security".psk = config.sops.secrets."wan-wifi-psk".path;
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };

    # SOPS secrets for WiFi SSID and PSK (only if WiFi enabled)
    sops.secrets."wan-wifi-ssid" = lib.mkIf config.networking.wireless.enable {
      sopsFile = ../../secrets/wan-wifi.yaml;
      key = "SSID";
    };
    sops.secrets."wan-wifi-psk" = lib.mkIf config.networking.wireless.enable {
      sopsFile = ../../secrets/wan-wifi.yaml;
      key = "PSK";
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

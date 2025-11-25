{ pkgs, lib, platform, config, ... }:
{
  networking = {
    networkmanager.enable = false;

    wireless = {
      enable = true;
    } // lib.optionalAttrs (config ? sops && config.sops.secrets ? "wireless-secrets") {
      # Point to a secrets file that will be managed by sops
      secretsFile = config.sops.secrets."wireless-secrets".path;
    };
  };
}
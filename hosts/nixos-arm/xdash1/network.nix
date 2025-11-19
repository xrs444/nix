{ pkgs, lib, platform, config, ... }:
{
  networking = {
    networkmanager.enable = false;
    
    wireless = {
      enable = true;
      # Point to a secrets file that will be managed by sops
      secretsFile = config.sops.templates.wireless-secrets.path;
    };
  };

}
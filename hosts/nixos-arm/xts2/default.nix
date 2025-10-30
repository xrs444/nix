{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
{
  imports = [
    ./disks.nix
#    ./network.nix
  ];
  
  # Changes for nixos-anywhere compatibility
  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
  ];
  
  # Enable SSH for nixos-anywhere
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # For initial setup
    };
  };
  
}
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
    ../common/hardware-arm64-server.nix
    ./disks.nix
#    ./network.nix
  ];
  
  # Additional kernel modules for nixos-anywhere compatibility
  # (base modules are provided by ../common/hardware-arm64-server.nix)
  
  # Enable SSH for nixos-anywhere
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # For initial setup
    };
  };
  
}
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
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./disks.nix
#    ./network.nix
  ];
  nixpkgs.hostPlatform = "aarch64-linux";
  
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
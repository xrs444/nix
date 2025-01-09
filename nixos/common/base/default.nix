{
  hostname,
  pkgs,
  lib,
  username,
  ...
}:
{
  imports = [
    ./boot.nix
    ./hardware.nix
    ./locale.nix
    ./nh.nix
#    ../services/firewall.nix
    ../services/openssh.nix
    ./disko.nix
    ./comin.nix
    ./packages.nix
 
  ];

  networking = {
    hostName = hostname;
  };

  environment.systemPackages = (import ./packages.nix { inherit pkgs; }).basePackages;

  programs = {
    zsh.enable = true;
  };

  services = {
    chrony.enable = true;
    journald.extraConfig = "SystemMaxUse=250M";
 #   flatpak.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  users.mutableUsers = true;

  # Create dirs for home-manager
  systemd.tmpfiles.rules = [ "d /nix/var/nix/profiles/per-user/${username} 0755 ${username} root" ];
}

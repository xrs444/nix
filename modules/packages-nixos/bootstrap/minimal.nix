# Minimal bootstrap module for ARM SD image
# Only enables networking and comin for initial provisioning

{ config, pkgs, lib, ... }:
{
  # Only enable the absolute minimum for remote provisioning
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault true;
  networking.wireless.enable = lib.mkDefault true;

  # Enable SSH for debugging (optional, can be removed)
  services.openssh.enable = lib.mkDefault true;
  services.openssh.settings = {
    PasswordAuthentication = lib.mkDefault false;
    PermitRootLogin = lib.mkDefault "yes";
  };

  # Enable comin for remote configuration
  services.comin.enable = true;
  services.comin.remotes = [
    {
      name = "origin";
      url = "https://github.com/xrs444/nix.git";
      branches.main.name = "main";
    }
  ];

  # Do not disable all services; allow comin and others to run
  users.users.root.password = ""; # No password for root (use SSH keys)

  # Optionally, set a minimal hostname
  networking.hostName = lib.mkDefault "bootstrap-arm";

  # Optionally, skip heavy modules (letsencrypt, etc.)
  minimalImage = true;

  # Explicitly disable ACME/letsencrypt for minimal image
  security.acme.acceptTerms = false;
  security.acme.certs = {};
  services.nginx.enable = lib.mkDefault false;
  services.nginx.virtualHosts = {};
}

# Base NixOS configuration shared between x86_64 and ARM platforms
{
  config,
  hostname,
  isInstall,
  isWorkstation,
  inputs,
  lib,
  modulesPath,
  outputs,
  pkgs,
  platform ? null,
  stateVersion,
  username,
  ...
}:
{
  imports = [
    inputs.determinate.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-snapd.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.comin.nixosModules.comin
    (modulesPath + "/installer/scan/not-detected.nix")
    ../modules/packages-common
    ../modules/packages-nixos
    ../modules/services
    # Cross-platform common configuration
    ./common
  ] ++ lib.optional isWorkstation ../modules/packages-workstation;

  # Base user configuration
  users.mutableUsers = true;
  users.users.thomas-local = {
    isNormalUser = true;
    home = "/home/thomas-local";
    description = "thomas-local";
    extraGroups = [ "wheel" "networkmanager" ];
    # openssh.authorizedKeys.keys = [ "ssh-dss " ];
  };

  # SOPS configuration
  sops = lib.mkIf (isInstall) {
    age = {
      keyFile = "/var/lib/private/sops/age/keys.txt";
      generateKey = false;
    };
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  # System configuration
  systemd = {
    extraConfig = "DefaultTimeoutStopSec=10s";
    tmpfiles.rules = [
      "d /var/lib/private/sops/age 0755 root root"
    ];
  };

  # Network configuration
  networking.nftables.enable = false;
  networking.firewall.enable = false;
  networking.firewall.allowPing = true;

  services.resolved = {
    enable = true;
    domains = [ "x.xrs444.net" ];
    fallbackDns = [ "172.18.10.250" ];
  };

  # Hardware/firmware updates
  services.fwupd.enable = true;
  
  # System state version
  system.stateVersion = stateVersion;
  
  # Nix configuration
  nix = {
    # Core nix settings are in ../common
    settings = {
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
  };
}
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
  platform,
  stateVersion,
  username,
  overlays,
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
    (./common/base/defaults/default.nix {
      inherit config hostname isInstall isWorkstation inputs lib modulesPath outputs pkgs platform stateVersion username overlays;
    })
    ./${hostname}
    ./common/base
    ./common/services
# ./common/users
  ]; # ++ lib.optional isWorkstation ./common/desktop;

  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";
    overlays = [
      outputs.overlays.additions
#      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  users.mutableUsers = true;
  users.users.thomas-local = {
    isNormalUser  = true;
    home  = "/home/thomas-local";
    description  = "thomas-local";
    extraGroups  = [ "wheel" "networkmanager" ];
#  openssh.authorizedKeys.keys  = [ "ssh-dss " ];
  };

  sops = lib.mkIf (isInstall) {
    age = {
      keyFile = "/var/lib/private/sops/age/keys.txt";
      generateKey = false;
    };
    defaultSopsFile = ../secrets/secrets.yaml;
  };

  systemd = {
    extraConfig = "DefaultTimeoutStopSec=10s";
    tmpfiles.rules = [
      "d /var/lib/private/sops/age 0755 root root"
    ];
  };

  networking.nftables.enable = false;
  networking.firewall.enable = false;
  networking.firewall.allowPing = true;

  services.resolved = {
    enable = true;
    domains = [ "x.xrs444.net" ];
    fallbackDns = [ "172.18.10.250" ];
  };

  nix = 
  let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "flakes nix-command";
      flake-registry = "";
      nix-path = config.nix.nixPath;
      trusted-users = [
        "root"
        "${username}"
      ];
      warn-dirty = false;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
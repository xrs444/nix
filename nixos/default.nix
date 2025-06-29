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
    ./${hostname}
    ./common/base
    ./common/services
#   ./common/users
  ]; # ++ lib.optional isWorkstation ./common/desktop;

  environment = {
    systemPackages =
      with pkgs;
      [
        git
        nix-output-monitor
        pciutils
      ]
      ++ lib.optionals isInstall [
        inputs.determinate.packages.${platform}.default
        inputs.fh.packages.${platform}.default
        inputs.nixos-needsreboot.packages.${platform}.default
        nvd
        nvme-cli
        rsync
        smartmontools
        sops
      ];
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
#      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # Or just specify overlays directly here, for example:
      # (_: _: { embr = inputs.embr.packages."${pkgs.system}".embr; })
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
      # Disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
      trusted-users = [
        "root"
        "${username}"
      ];
      warn-dirty = false;
    };
    # Disable channels
    channel.enable = false;
    # Make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  system = {
    activationScripts = {
      nixos-needsreboot = lib.mkIf (isInstall) {
        supportsDryActivation = true;
        text = "${lib.getExe inputs.nixos-needsreboot.packages.${pkgs.system}.default} \"$systemConfig\" || true";
      };
    };
    nixos.label = lib.mkIf isInstall "-";
    inherit stateVersion;
  };
  
}
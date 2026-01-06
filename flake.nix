# Summary: Nix flake entrypoint for HomeProd, defines inputs, outputs, and configuration for NixOS and Darwin systems.
{
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Increase download buffer to avoid warnings during flake evaluation
    download-buffer-size = 134217728; # 128 MiB (default is 64 MiB)
  };
  description = "nixos configuration";
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    comin.url = "github:nlewo/comin";
    comin.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    # Use main branch which has fix for nix-dev path issue
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*";
    nixos-needsreboot.url = "https://codeberg.org/Mynacol/nixos-needsreboot/archive/main.tar.gz";
    nixos-needsreboot.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "https://flakehub.com/f/gmodena/nix-flatpak/*";
    nix-snapd.url = "https://flakehub.com/f/io12/nix-snapd/*";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";
    quickemu.url = "https://flakehub.com/f/quickemu-project/quickemu/*";
    quickemu.inputs.nixpkgs.follows = "nixpkgs";
    quickgui.url = "https://flakehub.com/f/quickemu-project/quickgui/*";
    quickgui.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/0.1.887.tar.gz";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (self) outputs;
      stateVersion = "25.05";

      # Import overlays as a list from a single file
      allOverlays = import ./overlays/all.nix { inherit inputs; };

      # Unified host definitions with role-based service assignments
      hosts = {
        xsvr1 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          roles = [
            "kvm"
            "samba"
            "zfs"
            "iprouting"
            "talos"
            "kanidm-primary"
            "letsencrypt-primary"
            "cockpit"
            "homeassistant"
            "tailscale-package"
            "monitoring-server"
          ];
        };
        xsvr2 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          roles = [
            "kvm"
            "samba"
            "zfs"
            "iprouting"
            "talos"
            "kanidm-replica"
            "letsencrypt-host"
            "tailscale-package"
            "monitoring-client"
          ];
        };
        xsvr3 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          desktop = "xfce";
          roles = [
            "kvm"
            "samba"
            "iprouting"
            "talos"
            "letsencrypt-host"
            "tailscale-package"
            "monitoring-client"
          ];
        };
        xlabmgmt = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          desktop = "gnome";
          enableHomeManager = false;
          roles = [
            "bind"
            "monitoring-client"
          ];
        };
        xts1 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          roles = [
            "iprouting"
            "letsencrypt-host"
            "tailscale-exit-node"
            "monitoring-client"
          ];
        };
        xts2 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          roles = [
            "letsencrypt-host"
            "tailscale-exit-node"
            "monitoring-client"
          ];
        };
        xcomm1 = {
          user = "thomas-local";
          platform = "x86_64-linux";
          type = "nixos";
          desktop = "gnome";
          roles = [
            "letsencrypt-host"
            "monitoring-client"
          ];
        };
        xdash1 = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableWifi = true;
          roles = [ "monitoring-client" ];
        };
        xhac-radio = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          enableHomeManager = false;
          enableWifi = true;
          roles = [ "monitoring-client" ];
        };
        xlt1-t-vnixos = {
          user = "thomas-local";
          platform = "aarch64-linux";
          type = "nixos";
          desktop = "gnome";
          roles = [ ];
        };
        xlt1-t = {
          user = "xrs444";
          platform = "aarch64-darwin";
          type = "darwin";
          desktop = "aqua";
          enableHomeManager = false;
          roles = [ "tailscale-client" ];
        };
      };

      lib = import ./lib {
        inherit
          inputs
          outputs
          stateVersion
          hosts
          ;
        overlays = allOverlays;
      };

    in
    let
      allHomes = lib.mkAllHomes;
    in
    {
      homeConfigurations = allHomes;
      nixosConfigurations = lib.mkAllNixosConfigs // lib.forAllHosts lib.mkMinimalNixosConfig;
      darwinConfigurations = lib.mkAllDarwinConfigs;
      devShells = lib.forAllSystems (system: {
        qmk = import ./shells/qmk.nix { pkgs = inputs.nixpkgs.legacyPackages.${system}; };
      });
      checks = lib.forAllSystems (
        system:
        let
          validHomes = inputs.nixpkgs.lib.filterAttrs (
            _: cfg: cfg ? config && cfg.config ? activationPackage
          ) (inputs.nixpkgs.lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) allHomes);
        in
        inputs.nixpkgs.lib.mapAttrs' (name: cfg: {
          name = name;
          value = cfg.config.activationPackage;
        }) validHomes
      );
      nixosModules = {
        cockpit = import ./modules/packages-nixos/cockpit;
        comin = import ./modules/packages-nixos/comin;
        zfs = import ./modules/services/zfs;
        letsencrypt = import ./modules/services/letsencrypt;
        kanidm = import ./modules/services/kanidm;
        Samba = import ./modules/services/Samba;
        bind = import ./modules/services/bind;
        ffr = import ./modules/services/ffr;
        homeassistant = import ./modules/services/homeassistant;
        iprouting = import ./modules/services/iprouting;
        keepalived = import ./modules/services/keepalived;
        kvm = import ./modules/services/kvm;
        nfs = import ./modules/services/nfs;
        nixcache = import ./modules/services/nixcache;
        openssh = import ./modules/services/openssh;
        remotebuilds = import ./modules/services/remotebuilds;
        talos = import ./modules/services/talos;
        tailscale = import ./modules/services/tailscale;
      };
      formatter = lib.forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      overlays = {
        kanidm = import ./overlays/kanidm.nix { inherit inputs; };
        pkgs = import ./overlays/pkgs.nix { inherit inputs; };
        unstable = import ./overlays/unstable.nix { inherit inputs; };
      };
    };
}

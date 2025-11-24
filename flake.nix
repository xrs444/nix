{
  description = "nixos configuration";
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    comin.url = github:nlewo/comin;
    comin.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
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
  
  outputs = { self, ... }@inputs:
  let
    inherit (self) outputs;
    stateVersion = "25.05";

    # Import overlays as a list from a single file
    allOverlays = import ./overlays/all.nix { inherit inputs; };

    # Unified host definitions
    hosts = {
      xsvr1 = {
        user = "thomas-local";
        platform = "x86_64-linux";
        type = "nixos";
      };
      xsvr2 = {
        user = "thomas-local";
        platform = "x86_64-linux";
        type = "nixos";
      };
      xsvr3 = {
        user = "thomas-local";
        platform = "x86_64-linux";
        type = "nixos";
        desktop = "gnome";
      };
      xlabmgmt = {
        user = "thomas-local";
        platform = "x86_64-linux";
        type = "nixos";
        desktop = "gnome";
      };
      xts1 = {
        user = "thomas-local";
        platform = "aarch64-linux";
        type = "nixos";
      };
      xts2 = {
        user = "thomas-local";
        platform = "aarch64-linux";
        type = "nixos";
      };
      xcomm1 = {
        user = "thomas-local";
        platform = "x86_64-linux";
        type = "nixos";
        desktop = "gnome";
      };
      xdash1 = {
        user = "thomas-local";
        platform = "aarch64-linux";
        type = "nixos";
      };
      xhac-radio = {
        user = "thomas-local";
        platform = "aarch64-linux";
        type = "nixos";
      };
      xlt1-t-vnixos = {
        user = "thomas-local";
        platform = "x86_64-linux";
        type = "nixos";
        desktop = "gnome";
      };
      xlt1-t = {
        user = "xrs444";
        platform = "aarch64-darwin";
        type = "darwin";
        desktop = "aqua";
      };
    };


    lib = import ./lib {
      inherit inputs outputs stateVersion hosts;
      overlays = allOverlays;
    };

  in
  let
    allHomes = lib.mkAllHomes;
  in
  {
    homeConfigurations = allHomes;
    nixosConfigurations = lib.mkAllNixosConfigs;
    darwinConfigurations = lib.mkAllDarwinConfigs;
    nixosModules = {
      #cockpit = import ./modules/packages-nixos/cockpit;
      #comin = import ./modules/packages-nixos/comin;
      #tailscale = import ./modules/packages-nixos/tailscale;
      zfs = import ./modules/services/zfs;
      letsencrypt = import ./modules/services/letsencrypt;
      kanidm = import ./modules/services/kanidm;
      Samba = import ./modules/services/Samba;
      #bind = import ./modules/services/bind;
      #ffr = import ./modules/services/ffr;
      #homeassistant = import ./modules/services/homeassistant;
      #iprouting = import ./modules/services/iprouting;
      #keepalived = import ./modules/services/keepalived;
      #kvm = import ./modules/services/kvm;
      nfs = import ./modules/services/nfs;
      nixcache = import ./modules/services/nixcache;
      openssh = import ./modules/services/openssh;
      remotebuilds = import ./modules/services/remotebuilds;
      talos = import ./modules/services/talos;
      tailscaleService = import ./modules/services/tailscale;
    };
    formatter = lib.forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    overlays = {
      kanidm = import ./overlays/kanidm.nix { inherit inputs; };
      pkgs = import ./overlays/pkgs.nix { inherit inputs; };
      unstable = import ./overlays/unstable.nix { inherit inputs; };
    };
  };
}

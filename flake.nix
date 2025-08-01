{
  description = "nixos configuration";
  inputs = {
    comin.url = github:nlewo/comin;
    comin.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.10.0.tar.gz";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*";
    nixos-needsreboot.url = "https://codeberg.org/Mynacol/nixos-needsreboot/archive/main.tar.gz";
    nixos-needsreboot.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
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
  
  outputs = { self
    , nixpkgs
    , home-manager
    , nix-darwin
    , nix-homebrew
    , ...
  }@inputs:
  let
    inherit (self) outputs;
    stateVersion = "25.05";
    lib = import ./lib { inherit inputs outputs stateVersion ; };
  in
  {

    homeConfigurations = {
      # Servers
      "thomas-local@xsvr1" = lib.mkHome { hostname = "xsvr1"; };
      "thomas-local@xsvr2" = lib.mkHome { hostname = "xsvr2"; };
      "thomas-local@xsvr3" = lib.mkHome { hostname = "xsvr3"; };
      "thomas-local@xlabmgmt" = lib.mkHome { hostname = "xlabmgmt"; };
      "thomas.local@xts1" = lib.mkNixos { hostname = "xts1"; };
      # Auxiliary
      #        "thomas-local@xdash1" = lib.mkHome { hostname = "xdash1"; };
      #        "thomas-local@xhac-radio" = lib.mkHome { hostname = "xhac-radio"; };
      # Clients
      "thomas.local@xlt1-t-vnixos" = lib.mkNixos { hostname = "xlt1-t-vnixos"; };
      # Auxiliary
    };

    nixosConfigurations = {
      # Servers
      xsvr1 = lib.mkNixos { hostname = "xsvr1"; };
      xsvr2 = lib.mkNixos { hostname = "xsvr2"; };
      xsvr3 = lib.mkNixos { 
        hostname = "xsvr3";
        desktop = "gnome";
      };
      xlabmgmt = lib.mkNixos {
        hostname = "xlabmgmt";
        desktop = "gnome";
      };
      xts1 = lib.mkNixos {
        hostname = "xts1";
        platform = "aarch64-linux";
      };      
      xts2 = lib.mkNixos {
        hostname = "xts2";
        platform = "aarch64-linux";
      };    

      #       Auxiliary
      #          xdash1 = lib.mkNixos {
      #          hostname = "xdash1";
      #          platform = "aarch64-linux";
      #        };
      #        xhac-radio = lib.mkNixos {
      #          hostname = "xhac-radio";
      #          platform = "aarch64-linux";
      #        };

      # Clients

      xlt1-t-vnixos = lib.mkNixos {
        hostname = "xlt1-t-vnixos";
        desktop = "gnome";
        platform = "aarch64-linux";
      };
    
    };

    # macOS machines
    darwinConfigurations = {
      xlt1-t = lib.mkDarwin {
        hostname = "xlt1-t";
        username = "thomas-local";
        desktop = "aqua";
        platform = "aarch64-darwin";
      };
    };

    # Custom packages; accessible via 'nix build', 'nix shell', etc
    nixosModules = { lib, pkgs, platform, hostname,... }@args: import ./modules/nixos (args // { inherit lib pkgs; });
    formatter = lib.forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    overlays = import ./overlays { inherit inputs; };
    packages = lib.forAllSystems (system:
        let
          # Import nixpkgs for the target system, applying overlays directly
          pkgsWithOverlays = import nixpkgs {
             inherit system;
             config = { allowUnfree = true; }; # Ensure consistent config
             # Pass the list of overlay functions directly
             overlays = builtins.attrValues self.overlays;
          };
          # Import the function from pkgs/default.nix
          pkgsFunction = import ./pkgs;
          # Call the function with the fully overlaid package set
          customPkgs = pkgsFunction pkgsWithOverlays;
        in
        # Return the set of custom packages
        customPkgs
      );
  };
}

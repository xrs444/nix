{
  description = "nixos configuration";
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
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
    disko.url = "https://flakehub.com/f/nix-community/disko/1.10.0.tar.gz";
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
    
    # Define default users for each host
    hostUsers = {
      # Servers
      xsvr1 = "thomas-local";
      xsvr2 = "thomas-local";
      xsvr3 = "thomas-local";
      xlabmgmt = "thomas-local";
      xts1 = "thomas-local";
      xts2 = "thomas-local";
      xcomm1 = "xrs444";
      # Auxiliary
      xdash1 = "thomas-local";
      xhac-radio = "thomas-local";
      # Clients
      xlt1-t-vnixos = "thomas-local";
      # Darwin
      xlt1-t = "xrs444";
    };
    
    lib = import ./lib { inherit inputs outputs stateVersion hostUsers; };
  in
  {

    # Automatically generate home configurations from hostUsers mapping
    homeConfigurations = lib.mkAllHomes;

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
      };      
      xts2 = lib.mkNixos {
        hostname = "xts2";
      };    
      xcomm1 = lib.mkNixos {
        hostname = "xcomm1";
        desktop = "gnome";
      };

#       Auxiliary

      xdash1 = lib.mkNixos {
        hostname = "xdash1";
      };
      xhac-radio = lib.mkNixos {
          hostname = "xhac-radio";
       };

      # Clients

      xlt1-t-vnixos = lib.mkNixos {
        hostname = "xlt1-t-vnixos";
        desktop = "gnome";
      };
    
    };

    # macOS machines
    darwinConfigurations = {
      xlt1-t = lib.mkDarwin {
        hostname = "xlt1-t";
        desktop = "aqua";
      };
    };

    # Custom packages; accessible via 'nix build', 'nix shell', etc
    nixosModules = import ./modules/packages-nixos;
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

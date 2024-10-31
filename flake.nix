{
  description = "jnsgruk's nixos configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    master.url = "github:nixos/nixpkgs/master";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      stateVersion = "24.05";
      username = "thomas-local";

      libx = import ./lib {
        inherit
          self
          inputs
          outputs
          stateVersion
          username
          ;
      };
    in
    {
      # nix build .#homeConfigurations."jon@freyja".activationPackage
      homeConfigurations = {
        # Servers
        "${username}@xsvr1" = libx.mkHome { hostname = "xsvr1"; };
        "${username}@xsvr2" = libx.mkHome { hostname = "xsvr2"; };
        "${username}@xsvr3" = libx.mkHome { hostname = "xsvr3"; };
        };
      };

      nixosConfigurations = {
        # Desktop machines
        # Servers
        xsrv1 = libx.mkHost {
          hostname = "xsvr1";
          pkgsInput = nixpkgs;
        };
        xsrv2 = libx.mkHost {
          hostname = "xsvr2";
          pkgsInput = nixpkgs;
        };
        xsvr3 = libx.mkHost {
          hostname = "xsvr3";
          pkgsInput = nixpkgs;
        };
      };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = libx.forAllSystems (
        system:
        let
          pkgs = unstable.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs; }
      );

      # Custom overlays
      overlays = import ./overlays { inherit inputs; };

      # Devshell for bootstrapping
      # Accessible via 'nix develop' or 'nix-shell' (legacy)
      devShells = libx.forAllSystems (
        system:
        let
          pkgs = unstable.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = libx.forAllSystems (system: self.packages.${system}.nixfmt-plus);
}


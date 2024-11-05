{
  description = " nixos configuration";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/nixos/nixpkgs/0.2405.*";
    unstable.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0";
    master.url = "github:nixos/nixpkgs/master";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
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
      
      helper = import ./lib {
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
        "${username}@xsvr1" = helper.mkHome { hostname = "xsvr1"; };
        "${username}@xsvr2" = helper.mkHome { hostname = "xsvr2"; };
        "${username}@xsvr3" = helper.mkHome { hostname = "xsvr3"; };
        };

      nixosConfigurations = {
        # Desktop machines
        # Servers
        xsvr1 = helper.mkHost {
          hostname = "xsvr1";
          pkgsInput = nixpkgs;
        };
        xsvr2 = helper.mkHost {
          hostname = "xsvr2";
          pkgsInput = nixpkgs;
        };
        xsvr3 = helper.mkHost {
          hostname = "xsvr3";
          pkgsInput = nixpkgs;
        };
      };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = helper.forAllSystems (
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
      devShells = helper.forAllSystems (
        system:
        let
          pkgs = unstable.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );
      formatter = helper.forAllSystems (system: self.packages.${system}.nixfmt-plus);
    };
}

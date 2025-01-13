{
  description = " nixos configuration";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/nixos/nixpkgs/0.2411.*";
    nixpkgs-unstable.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/0.1.887.tar.gz";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*";
    nixos-needsreboot.url = "https://codeberg.org/Mynacol/nixos-needsreboot/archive/0.2.2.tar.gz";
    nixos-needsreboot.inputs.nixpkgs.follows = "nixpkgs";
  };
    outputs =
    { self, nix-darwin, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "24.11";
      helper = import ./lib { inherit inputs outputs stateVersion; };
    in
    {
      homeConfigurations = {
        # Servers
        "thomas-local@xsvr1" = helper.mkHome { hostname = "xsvr1"; };
        "thomas-local@xsvr2" = helper.mkHome { hostname = "xsvr2"; };
        "thomas-local@xsvr3" = helper.mkHome { hostname = "xsvr3"; };
        };

      nixosConfigurations = {
        # Desktop machines
        # Servers
        xsvr1 = helper.mkHost {
          hostname = "xsvr1";
        };
        xsvr2 = helper.mkHost {
          hostname = "xsvr2";
        };
        xsvr3 = helper.mkHost {
          hostname = "xsvr3";
          desktop = "gnome";
        };
      };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
     packages = helper.forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

      # Custom overlays
      overlays = import ./overlays { inherit inputs; };

      # Devshell for bootstrapping
      # Accessible via 'nix develop' or 'nix-shell' (legacy)
      devShells = helper.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );
      formatter = helper.forAllSystems (system: self.packages.${system}.nixfmt-plus);
    };
}

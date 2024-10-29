{
  description = "flake";

  # ...

  outputs = { nixpkgs, ... }@inputs: {

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/host1/configuration.nix
        ./nixosModules
      ];
    };

    homeManagerModules.default = ./homeManagerModules;

  };

}
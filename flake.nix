{
  description = "flake";

  # ...

  outputs = { nixpkgs, ... }@inputs: {

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./nixos/xsrv1/configuration.nix
        ./nixos/modules/apps
        ./nixos/modules/services
      ];
    };

    homeManagerModules.default = ./homeManagerModules;

  };

}
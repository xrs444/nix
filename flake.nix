{
  description = "flake";

  # ...

  outputs = { nixpkgs, ... }@inputs: {

    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./nixos/xsrv1/default.nix
        ./nixos/modules/apps
        ./nixos/modules/services
      ];
    };

    homeManagerModules.default = ./homeManagerModules;

  };

  outputs =
    { self, nix-darwin, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "24.05";
      helper = import ./lib { inherit inputs outputs stateVersion; };
    in{
      nixosConfigurations = {
              # Servers
        xsrv-1 = helper.mkNixos { hostname = "xsrv1"; };
        xrsv-2 = helper.mkNixos { hostname = "xsrv2"; };
        xrsv-3 = helper.mkNixos { hostname = "xsrv3"; };
    };
      darwinConfigurations = {
        xlt1-tl = helper.mkDarwin {
        hostname = "xlt1-tl";
        };
      };

};
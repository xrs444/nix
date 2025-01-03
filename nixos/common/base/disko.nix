{
  inputs = {
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixosConfigurations.nixos = {
    # ...
    modules = [
      ./configuration.nix
      inputs.disko.nixosModules.disko
    ];
  };
}

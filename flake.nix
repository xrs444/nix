{
  description = "flake";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/nixos/nixpkgs/0.2405.*";
    nixpkgs-unstable.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-needtoreboot.url = "github:thefossguy/nixos-needsreboot";
    nixos-needtoreboot.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # FlakeHub

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";
    nix-flatpak.url = "https://flakehub.com/f/gmodena/nix-flatpak/*.tar.gz";
  };

  # ...

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
        xsrv1 = helper.mkNixos { hostname = "xsrv1"; };
        xrsv2 = helper.mkNixos { hostname = "xsrv2"; };
        xrsv3 = helper.mkNixos { hostname = "xsrv3"; };
    };
      darwinConfigurations = {
        xlt1-tl = helper.mkDarwin {
        hostname = "xlt1-tl";
        };
      };
        
  overlays = import ./overlays { inherit inputs; };
      # Custom NixOS modules
  nixosModules = import ./modules/nixos;
      # Custom packages; acessible via 'nix build', 'nix shell', etc
  packages = helper.forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      # Formatter for .nix files, available via 'nix fmt'
  formatter = helper.forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

  };
}

{
  description = "Wimpy's NixOS, nix-darwin and Home Manager Configuration";
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

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # FlakeHub
   
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0";

    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0";

    nix-flatpak.url = "https://flakehub.com/f/gmodena/nix-flatpak/*.tar.gz";

#    quickemu.url = "https://flakehub.com/f/quickemu-project/quickemu/*.tar.gz";
#    quickemu.inputs.nixpkgs.follows = "nixpkgs";
#    quickgui.url = "https://flakehub.com/f/quickemu-project/quickgui/*.tar.gz";
#    quickgui.inputs.nixpkgs.follows = "nixpkgs";

  };
  outputs =
    { self, nix-darwin, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "24.05";
      helper = import ./lib { inherit inputs outputs stateVersion; };
    in
    {
      # home-manager switch -b backup --flake $HOME/Zero/nix-config
      # nix run nixpkgs#home-manager -- switch -b backup --flake "${HOME}/Zero/nix-config"
      homeConfigurations = {
        # Workstations
#        "thomas-local@xdt1-tl" = helper.mkHome {
#          hostname = "xdt1-tl";
#          desktop = "gnome";
#       };

        # Servers
        "thomas-local@xsrv1" = helper.mkHome { hostname = "xsrv1"; };
        "thomas-local@xsrv2" = helper.mkHome { hostname = "xsrv2"; };
        "thomas-local@xsrv3" = helper.mkHome { hostname = "xsrv3"; };

        };
      };
      nixosConfigurations = {
        # Workstations
        #  - sudo nixos-rebuild boot --flake $HOME/Zero/nix-config
        #  - sudo nixos-rebuild switch --flake $HOME/Zero/nix-config
        #  - nix build .#nixosConfigurations.{hostname}.config.system.build.toplevel
        #  - nix run github:nix-community/nixos-anywhere -- --flake '.#{hostname}' root@{ip-address}
#        xdt1-tl = helper.mkNixos {
#          hostname = "xdt1-tl";
#          desktop = "hyprland";
#        };

        # Servers
        xsrv1 = helper.mkNixos { hostname = "xsrv1"; };
        xsrv2 = helper.mkNixos { hostname = "xsrv2"; };
        xsrv3 = helper.mkNixos { hostname = "xsrv3"; };        

      };
      #nix run nix-darwin -- switch --flake ~/Zero/nix-config
      #nix build .#darwinConfigurations.{hostname}.config.system.build.toplevel
#      darwinConfigurations = {
#        xlt1-t = helper.mkDarwin {
#        hostname = "xlt1-tl";
#      };
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Custom NixOS modules
      nixosModules = import ./modules/nixos;
      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = helper.forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      # Formatter for .nix files, available via 'nix fmt'
      formatter = helper.forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}

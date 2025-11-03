{ inputs, outputs, stateVersion, hosts }:

let
  inherit (inputs) nixpkgs home-manager nix-darwin;

  # Helper function to generate system configurations for all supported architectures
  forAllSystems = nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  # Helper to filter hosts by type
  hostsByType = type: nixpkgs.lib.filterAttrs (_: v: v.type == type) hosts;

  # Generate all home configurations from hosts mapping
  mkAllHomes = builtins.mapAttrs (hostname: host:
    mkHome { inherit hostname host; }
  ) hosts;

  # Create Home Manager configuration for a host
  mkHome = { hostname, host }: 
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${host.platform};
      extraSpecialArgs = { 
        inherit inputs outputs stateVersion hostname;
        platform = host.platform;
        username = host.user;
        desktop = host.desktop or null;
        host = host;
      };
      modules = [
        ../homemanager
        ../homemanager/users/${host.user}
      ];
    };

  # Generate all NixOS configurations from hosts mapping
  mkAllNixosConfigs = builtins.mapAttrs (hostname: host:
    mkNixos { inherit hostname host; }
  ) (hostsByType "nixos");

  # Create NixOS configuration for a host
  mkNixos = { hostname, host }: 
    nixpkgs.lib.nixosSystem {
      system = host.platform;
      modules = [
        {
          nixpkgs.overlays = builtins.attrValues outputs.overlays;
          nixpkgs.config.allowUnfree = true;
        }
        ../hosts/nixos
        ../hosts/nixos/${hostname}
      ] ++ nixpkgs.lib.optionals (host.desktop or null != null) [
        ../hosts/nixos/${hostname}/desktop.nix
      ];
      specialArgs = {
        inherit inputs outputs stateVersion hostname;
        platform = host.platform;
        username = host.user;
        desktop = host.desktop or null;
        host = host;
        isInstall = host.isInstall or false;
        isWorkstation = host.isWorkstation or false;
      };
    };

  # Generate all Darwin configurations from hosts mapping
  mkAllDarwinConfigs = builtins.mapAttrs (hostname: host:
    mkDarwin { inherit hostname host; }
  ) (hostsByType "darwin");

  # Create Darwin configuration for a host
  mkDarwin = { hostname, host }: 
    nix-darwin.lib.darwinSystem {
      system = host.platform;
      specialArgs = { 
        inherit inputs outputs stateVersion hostname;
        platform = host.platform;
        username = host.user;
        desktop = host.desktop or null;
        host = host;
      };
      modules = [
        {
          nixpkgs.overlays = builtins.attrValues outputs.overlays;
          nixpkgs.config.allowUnfree = true;
        }
        ../hosts/darwin
        ../hosts/darwin/${hostname}
      ];
    };

in {
  forAllSystems = forAllSystems;
  mkAllHomes = mkAllHomes;
  mkHome = mkHome;
  mkAllNixosConfigs = mkAllNixosConfigs;
  mkNixos = mkNixos;
  mkAllDarwinConfigs = mkAllDarwinConfigs;
  mkDarwin = mkDarwin;
}
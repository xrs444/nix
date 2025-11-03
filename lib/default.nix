{ inputs, outputs, stateVersion, hosts, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Helper function for creating packages across systems
  forAllSystems = lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  # Filter hosts by type
  nixosHosts = lib.filterAttrs (_: host: host.type == "nixos") hosts;
  darwinHosts = lib.filterAttrs (_: host: host.type == "darwin") hosts;

  # Common module builder for NixOS
  mkNixosConfig = hostName: hostConfig:
    let
      # Determine the correct host directory based on platform
      hostDir = if hostConfig.platform == "aarch64-linux" 
                then ../hosts/nixos-arm
                else ../hosts/nixos;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = hostConfig.platform;
      specialArgs = {
        inherit inputs outputs stateVersion;
        hostname = hostName;
        username = hostConfig.user;
        platform = hostConfig.platform;
        isInstall = false;
        isWorkstation = hostConfig.desktop or null != null;
      };
      modules = [
        ../hosts/base-nixos.nix
        (hostDir + "/${hostName}")
        ../modules/roles
        ../modules/services
        ../modules/packages-darwin
        ../modules/packages-nixos
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {
              inherit inputs outputs stateVersion;
              username = hostConfig.user;
              desktop = hostConfig.desktop or null;
            };
            users.${hostConfig.user} = import ../homemanager;
          };
        }
      ];
    };

  # Common module builder for Darwin
  mkDarwinConfig =
    hostName:
    hostConfig:
    inputs.nix-darwin.lib.darwinSystem {
      system = hostConfig.platform;
      specialArgs = {
        inherit inputs outputs stateVersion;
        hostname = hostName;
        username = hostConfig.user;
        platform = hostConfig.platform;
        desktop = hostConfig.desktop or null;
      };
      modules = [
        ../hosts/base-darwin.nix
        (../hosts/darwin + "/${hostName}")
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {
              inherit inputs outputs stateVersion;
              username = hostConfig.user;
              desktop = hostConfig.desktop or null;
            };
            users.${hostConfig.user} = import ../homemanager;
          };
        }
      ];
    };

  # Build home-manager configurations
  mkHome = hostName: hostConfig:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = hostConfig.platform;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit inputs outputs stateVersion;
        username = hostConfig.user;
        desktop = hostConfig.desktop or null;
      };
      modules = [ ../homemanager ];
    };

  mkAllNixosConfigs = builtins.mapAttrs mkNixosConfig nixosHosts;
  mkAllDarwinConfigs = builtins.mapAttrs mkDarwinConfig darwinHosts;
  mkAllHomes = builtins.mapAttrs mkHome hosts;

in
{
  inherit
    forAllSystems
    mkNixosConfig
    mkDarwinConfig
    mkAllNixosConfigs
    mkAllDarwinConfigs
    mkAllHomes
    ;
}
{ inputs, outputs, stateVersion, hosts, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Filter hosts by type
  nixosHosts = lib.filterAttrs (_: host: host.type == "nixos") hosts;
  darwinHosts = lib.filterAttrs (_: host: host.type == "darwin") hosts;

  # Determine the correct base module for each host type
  getBaseModule = hostConfig:
    if hostConfig.platform == "aarch64-linux" then
      ../hosts/nixos-arm
    else if hostConfig.type == "nixos" then
      ../hosts/nixos
    else if hostConfig.type == "darwin" then
      ../hosts/darwin
    else
      throw "Unknown host type: ${hostConfig.type}";

  # Common module builder for NixOS
  mkNixosConfig =
    hostName:
    hostConfig:
    lib.nixosSystem {
      system = hostConfig.platform;
      specialArgs = {
        inherit inputs outputs stateVersion;
        hostname = hostName;
        username = hostConfig.user;
        platform = hostConfig.platform;
        desktop = hostConfig.desktop or null;
        isInstall = hostConfig.installer or false;
        isWorkstation = builtins.hasAttr "desktop" hostConfig;
      };
      modules = [
        (getBaseModule hostConfig)  # This imports the platform wrapper which handles everything
        inputs.home-manager.nixosModules.home-manager
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
        (getBaseModule hostConfig)
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
    mkNixosConfig
    mkDarwinConfig
    mkAllNixosConfigs
    mkAllDarwinConfigs
    mkAllHomes
    ;
}
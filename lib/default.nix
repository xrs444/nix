{ inputs, outputs, stateVersion, hosts, overlays }:

let
  unstable = import ../overlays/unstable.nix { inherit inputs; };
in
rec {
  # Build NixOS configurations
  mkNixosConfig = hostName: hostConfig:
    let
      isArm = hostConfig.platform == "aarch64-linux";
      overlaysList = import ../overlays/all.nix { inherit inputs; };
      modulesList = [
        { nixpkgs.overlays = overlaysList;
          nixpkgs.config.allowUnfree = true;
        }
        (if isArm then ../hosts/nixos-arm/${hostName}/default.nix else ../hosts/nixos/${hostName}/default.nix)
      ];
      debugModules = builtins.trace (
        "DEBUG: modulesList for host " + hostName + ":\n" +
        builtins.concatStringsSep "\n" (map (m: (
          if builtins.isAttrs m then "ATTRSET: " + (builtins.toJSON (builtins.attrNames m))
          else if builtins.isList m then "LIST: " + (builtins.toJSON m)
          else if builtins.isPath m then "PATH: " + toString m
          else if builtins.isFunction m then "FUNCTION"
          else builtins.toJSON m
        )) modulesList)
      ) modulesList;
    in
      inputs.nixpkgs.lib.nixosSystem {
        system = hostConfig.platform;
        specialArgs = {
          inherit inputs stateVersion;
          hostname = hostName;
          username = hostConfig.user;
          platform = hostConfig.platform;
          desktop = hostConfig.desktop or null;
          isWorkstation = (hostConfig.desktop or null) != null;
        };
        modules = debugModules;
      };

  # Build Darwin configurations
  mkDarwinConfig = hostName: hostConfig:
    let
      modulesList = [
        {
          nixpkgs.overlays = [ overlays.kanidm overlays.pkgs overlays.unstable ];
          nixpkgs.config.allowUnfree = true;
        }
        ../hosts/darwin/default.nix
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
            users.${hostConfig.user} = ../homemanager;
          };
        }
      ];
    in
    inputs.nix-darwin.lib.darwinSystem {
      system = hostConfig.platform;
      specialArgs = {
        inherit inputs stateVersion;
        hostname = hostName;
        username = hostConfig.user;
        platform = hostConfig.platform;
        desktop = hostConfig.desktop or null;
      };
      modules = builtins.trace ("darwinSystem modules for " + hostName + ": " + builtins.toJSON (map (m: if builtins.isPath m then toString m else if builtins.isAttrs m && m ? _type && m._type == "derivation" then m.name else builtins.typeOf m) modulesList)) modulesList;
    };

  # Build home-manager configurations
  mkHome = hostName: hostConfig:
    let
      userConfigPath = ../homemanager/users/${hostConfig.user}/default.nix;
      hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = hostConfig.platform;
          config.allowUnfree = true;
          nixpkgs.overlays = [ overlays.kanidm overlays.pkgs overlays.unstable ];
        };
        extraSpecialArgs = {
          inherit inputs outputs stateVersion;
          username = hostConfig.user;
          desktop = hostConfig.desktop or null;
        };
        modules = [ userConfigPath ];
      };
    in {
      config = hmConfig;
    };

  # Utility functions for flake outputs
  mkAllNixosConfigs =
    let
      nixosHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "nixos") hosts;
    in inputs.nixpkgs.lib.mapAttrs mkNixosConfig nixosHosts;

  mkAllDarwinConfigs =
    let
      darwinHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "darwin") hosts;
    in inputs.nixpkgs.lib.mapAttrs mkDarwinConfig darwinHosts;

  mkAllHomes =
    inputs.nixpkgs.lib.mapAttrs (hostName: hostConfig: mkHome hostName hostConfig) hosts;

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}

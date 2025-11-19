{ inputs
, outputs
, stateVersion
, hosts
, ...
}:
let
  # Import overlays as a set for use across all configurations
  overlays = {
    kanidm = import ../overlays/kanidm.nix { inherit inputs; };
    pkgs = import ../overlays/pkgs.nix { inherit inputs; };
    unstable = import ../overlays/unstable.nix { inherit inputs; };
  };
  
  # Build NixOS configurations
  mkNixosConfig = hostName: hostConfig:
    let
      # Check if ARM-specific config exists
      armPath = ../hosts/nixos-arm + "/${hostName}";
      hasArmConfig = builtins.pathExists armPath;
      
      # Check if x86_64-specific config exists
      nixosPath = ../hosts/nixos + "/${hostName}";
      hasNixosConfig = builtins.pathExists nixosPath;
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
      modules = [
        # Apply overlays at the nixpkgs instantiation level - FIRST
        {
          nixpkgs.overlays = [ overlays.kanidm overlays.pkgs overlays.unstable ];
          nixpkgs.config.allowUnfree = true;
        }
        # Set kanidm package in a separate module that has access to pkgs
        ({ pkgs, ... }: {
          services.kanidm.package = inputs.nixpkgs.lib.mkOverride 900 pkgs.kanidm_1_7;
        })
        ../hosts/base-nixos.nix
        ../modules/services/default.nix
        ../modules/packages-nixos
        inputs.disko.nixosModules.disko
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
      ]
      ++ (if hostConfig.platform == "aarch64-linux" then [ (import "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix") ] else [])
      ++ (hostConfig.extraModules or [])
      # Conditionally add host-specific configs
      ++ (if hasNixosConfig then [ nixosPath ] else [])
      ++ (if hasArmConfig then [ armPath ] else []);
    };

  # Build Darwin configurations
  mkDarwinConfig = hostName: hostConfig:
    inputs.nix-darwin.lib.darwinSystem {
      system = hostConfig.platform;
      specialArgs = {
        inherit inputs stateVersion;
        hostname = hostName;
        username = hostConfig.user;
        platform = hostConfig.platform;
        desktop = hostConfig.desktop or null;
      };
      modules = [
        # Apply overlays for Darwin too
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
            users.${hostConfig.user} = import ../homemanager;
          };
        }
      ];
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
        activationPackage = hmConfig.activationPackage;
      };

  # Filter hosts by type
  nixosHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "nixos") hosts;
  darwinHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "darwin") hosts;

in
{
  # Generate all configurations
  mkAllNixosConfigs =
    let
      # Normal configs
      normal = inputs.nixpkgs.lib.mapAttrs mkNixosConfig nixosHosts;
      # Minimal configs: add a module that sets minimalImage = true
      minimal = inputs.nixpkgs.lib.mapAttrs (
        hostName: hostConfig:
          mkNixosConfig hostName (hostConfig // {
            extraModules = [ { minimalImage = true; } ];
          })
      ) nixosHosts;
    in
      normal // (inputs.nixpkgs.lib.mapAttrs' (
        hostName: _:
          { name = hostName + "-minimal";
            value = mkNixosConfig hostName (nixosHosts.${hostName} // {
              extraModules = [ { minimalImage = true; } ];
            });
          }
      ) nixosHosts);
  mkAllDarwinConfigs = inputs.nixpkgs.lib.mapAttrs mkDarwinConfig darwinHosts;
  mkAllHomes = inputs.nixpkgs.lib.mapAttrs mkHome hosts;

  # Utility to apply function to all systems
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}

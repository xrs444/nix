{ inputs
, outputs
, stateVersion
, hosts
, ...
}:
let
  # Import overlays once for use across all configurations
  allOverlays = import ../overlays { inherit inputs; };
  
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
        inherit inputs outputs stateVersion;
        hostname = hostName;
        username = hostConfig.user;
        platform = hostConfig.platform;
        desktop = hostConfig.desktop or null;
      };
      modules = [
        # Apply overlays at the nixpkgs instantiation level - FIRST
        {
          nixpkgs.overlays = [
            allOverlays.additions
            allOverlays.modifications
            allOverlays.unstable-packages
          ];
          nixpkgs.config.allowUnfree = true;
          
          # Set kanidm package default here with higher priority
          services.kanidm.package = inputs.nixpkgs.lib.mkOverride 900 (
            (import inputs.nixpkgs {
              system = hostConfig.platform;
              overlays = builtins.attrValues allOverlays;
            }).kanidm_1_7
          );
        }
        ../hosts/base-nixos.nix
        ../modules/services
        ../modules/packages-nixos
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
      # Conditionally add host-specific configs
      ++ (if hasNixosConfig then [ nixosPath ] else [])
      ++ (if hasArmConfig then [ armPath ] else []);
    };

  # Build Darwin configurations
  mkDarwinConfig = hostName: hostConfig:
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
        # Apply overlays for Darwin too
        {
          nixpkgs.overlays = [
            allOverlays.additions
            allOverlays.modifications
            allOverlays.unstable-packages
          ];
          nixpkgs.config.allowUnfree = true;
        }
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
        overlays = [
          allOverlays.additions
          allOverlays.modifications
          allOverlays.unstable-packages
        ];
      };
      extraSpecialArgs = {
        inherit inputs outputs stateVersion;
        username = hostConfig.user;
        desktop = hostConfig.desktop or null;
      };
      modules = [ ../homemanager ];
    };

  # Filter hosts by type
  nixosHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "nixos") hosts;
  darwinHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "darwin") hosts;

in
{
  # Generate all configurations
  mkAllNixosConfigs = inputs.nixpkgs.lib.mapAttrs mkNixosConfig nixosHosts;
  mkAllDarwinConfigs = inputs.nixpkgs.lib.mapAttrs mkDarwinConfig darwinHosts;
  mkAllHomes = inputs.nixpkgs.lib.mapAttrs mkHome hosts;

  # Utility to apply function to all systems
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
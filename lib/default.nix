{
  inputs,
  outputs,
  stateVersion,
  hosts,
  overlays,
}:

rec {
  # Generate all Home Manager configurations for all users in hosts
  mkAllHomes =
    let
      homeHosts = inputs.nixpkgs.lib.filterAttrs (
        _: v: v.type == null || v.type == "nixos" || v.type == "darwin"
      ) hosts;
    in
    inputs.nixpkgs.lib.mapAttrs (
      hostName: hostConfig:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = hostConfig.platform;
          config.allowUnfree = true;
          overlays = overlays ++ [
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                system = final.system;
                config.allowUnfree = true;
              };
            })
          ];
        };
        extraSpecialArgs = {
          inherit inputs outputs stateVersion;
          username = hostConfig.user;
          desktop = hostConfig.desktop or null;
          platform = hostConfig.platform;
        };
        modules = [
          (
            { config, specialArgs, ... }:
            {
              home.username = specialArgs.username;
              home.homeDirectory =
                if specialArgs.platform == "aarch64-darwin" || specialArgs.platform == "x86_64-darwin" then
                  "/Users/${specialArgs.username}"
                else
                  "/home/${specialArgs.username}";
            }
          )
          (../homemanager/users + "/${hostConfig.user}/default.nix")
        ];
      }
    ) homeHosts;
  mkAllNixosConfigs =
    let
      nixosHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "nixos") hosts;
    in
    inputs.nixpkgs.lib.mapAttrs mkNixosConfig nixosHosts;

  mkAllDarwinConfigs =
    let
      darwinHosts = inputs.nixpkgs.lib.filterAttrs (_: v: v.type == "darwin") hosts;
    in
    inputs.nixpkgs.lib.mapAttrs mkDarwinConfig darwinHosts;
  mkHome =
    hostName: hostConfig:
    let
      userConfigPath = ../homemanager/users/${hostConfig.user}/default.nix;
      hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = hostConfig.platform;
          config.allowUnfree = true;
          overlays = overlays ++ [
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                system = final.system;
                config.allowUnfree = true;
              };
            })
          ];
        };
        extraSpecialArgs = {
          inherit inputs outputs stateVersion;
          username = hostConfig.user;
          desktop = hostConfig.desktop or null;
          platform = hostConfig.platform;
        };
        modules = [
          (
            { config, specialArgs, ... }:
            {
              home.username = specialArgs.username;
              home.homeDirectory =
                if specialArgs.platform == "aarch64-darwin" || specialArgs.platform == "x86_64-darwin" then
                  "/Users/${specialArgs.username}"
                else
                  "/home/${specialArgs.username}";
            }
          )
          userConfigPath
        ];
      };
    in
    {
      config = hmConfig;
      pkgs = hmConfig.pkgs;
    };

  # Build Darwin configurations
  mkDarwinConfig =
    hostName: hostConfig:
    let
      modulesList = [
        {
          nixpkgs.overlays = overlays;
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
      modules = modulesList;
    };

  # Build home-manager configurations
  mkNixosConfig =
    hostName: hostConfig:
    let
      isArm = hostConfig.platform == "aarch64-linux";
      # List of ARM hosts with disks.nix
      armHostsWithDisko = [
        "xts1"
        "xts2"
        "xdash1"
        "xlt1-t-vnixos"
      ];
      modulesList = [
        { nixpkgs.overlays = overlays; }
      ]
      ++ (
        if isArm && builtins.elem hostName armHostsWithDisko then
          [
            inputs.disko.nixosModules.disko
            (import (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image.nix"))
          ]
        else
          [ ]
      )
      ++ [
        (
          if isArm then ../hosts/nixos-arm/${hostName}/default.nix else ../hosts/nixos/${hostName}/default.nix
        )
      ];
      debugModules = modulesList;
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
        minimalImage = true;
      };
      modules = modulesList;
    };
  mkMinimalNixosConfig =
    hostName: hostConfig:
    let
      isArm = hostConfig.platform == "aarch64-linux";
      modulesList = [
        { nixpkgs.overlays = overlays; }
      ]
      ++ (
        if isArm then
          [
            inputs.disko.nixosModules.disko
            (import (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image.nix"))
          ]
        else
          [ ]
      )
      ++ [
        (
          if isArm then ../hosts/nixos-arm/${hostName}/minimal.nix else ../hosts/nixos/${hostName}/minimal.nix
        )
      ];
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
        minimalImage = true;
      };
      modules = modulesList;
    };
  forAllHosts =
    f:
    builtins.listToAttrs (
      map (host: {
        name = "${host}-minimal";
        value = f host hosts.${host};
      }) (builtins.attrNames hosts)
    );
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}

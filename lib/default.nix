# Summary: Core Nix library for HomeProd, provides functions for Home Manager and NixOS configuration generation.
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
      base = inputs.nixpkgs.lib.mapAttrs (
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
      # Patch: ensure xrs444 for aarch64-darwin is always present
      patched =
        if base ? xrs444 then
          base
        else
          base
          // {
            xrs444 = inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                system = "aarch64-darwin";
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
                username = "xrs444";
                desktop = null;
                platform = "aarch64-darwin";
              };
              modules = [
                (
                  { config, specialArgs, ... }:
                  {
                    home.username = specialArgs.username;
                    home.homeDirectory = "/Users/${specialArgs.username}";
                  }
                )
                ../homemanager/users/xrs444/default.nix
              ];
            };
          };
    in
    patched;
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
      ]
      ++ (
        if hostConfig.enableHomeManager or true then
          [
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
          ]
        else
          [ ]
      );
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
        (import
          (
            if isArm then ../hosts/nixos-arm/${hostName}/default.nix else ../hosts/nixos/${hostName}/default.nix
          )
          {
            inherit inputs stateVersion overlays;
            hostname = hostName;
            username = hostConfig.user;
            platform = hostConfig.platform;
            desktop = hostConfig.desktop or null;
            lib = inputs.nixpkgs.lib;
            config = { };
            pkgs = import inputs.nixpkgs { system = hostConfig.platform; };
          }
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
        lib = inputs.nixpkgs.lib;
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
    let
      nixosHosts = builtins.filter (host: hosts.${host}.type == "nixos") (builtins.attrNames hosts);
    in
    builtins.listToAttrs (
      map (host: {
        name = "${host}-minimal";
        value = f host hosts.${host};
      }) nixosHosts
    );
  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}

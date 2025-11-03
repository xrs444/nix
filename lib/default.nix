{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  inherit (inputs) self;

  # Import the host configurations
  nixosHosts = import ../hosts/nixos-hosts.nix;
  darwinHosts = import ../hosts/darwin-hosts.nix;

  # Common module builder for NixOS
  mkNixosConfig =
    hostName:
    { system, ... }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ../hosts/${hostName}.nix
        # Remove extraModules from here - let each host import what it needs
      ];
    };

  # Common module builder for Darwin
  mkDarwinConfig =
    hostName:
    { system, ... }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ../hosts/${hostName}.nix
        # Remove extraModules from here
      ];
    };

  mkAllNixosConfigs = builtins.mapAttrs (_: mkNixosConfig) nixosHosts;
  mkAllDarwinConfigs = builtins.mapAttrs (_: mkDarwinConfig) darwinHosts;
in
{
  inherit
    mkNixosConfig
    mkDarwinConfig
    mkAllNixosConfigs
    mkAllDarwinConfigs
    ;
}
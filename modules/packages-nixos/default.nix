# Summary: NixOS module for NixOS-specific packages, imports submodules and configures Kanidm server URI.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  kanidmServerUri = "https://idm.xrs444.net";
  currentDir = ./.;
  hasDefaultNix =
    name: type: type == "directory" && builtins.pathExists (currentDir + "/" + name + "/default.nix");
  directories = lib.filterAttrs hasDefaultNix (builtins.readDir currentDir);
  importDirectory = name: import (currentDir + "/${name}");
in
{
  # Always import all submodules. Do not use config in imports to avoid recursion.
  # Submodules should use mkIf/mkEnableOption for conditional logic based on config.minimalImage.
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;

  environment.systemPackages = with pkgs; [ ];

  services.kanidm = {
    enableClient = lib.mkDefault true;
    clientSettings = {
      uri = kanidmServerUri;
      verify_ca = true;
    };
  };
}

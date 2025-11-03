{ lib, ... }:
let
  currentDir = ./.;
  # Only include directories that contain a default.nix file
  isModuleDir = name: type:
    type == "directory" &&
    builtins.pathExists (currentDir + "/${name}/default.nix");
  moduleDirs = lib.filterAttrs isModuleDir (builtins.readDir currentDir);
  importDirectory = name: import (currentDir + "/${name}");
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) moduleDirs;
}
{ lib, ... }:
let
  currentDir = ./.;
  isDirectoryAndNotTemplate = name: type:
    type == "directory" && name != "templates";
  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
  importDirectory = name: currentDir + "/${name}";
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;
}
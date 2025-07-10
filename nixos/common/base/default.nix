{ config, lib, ... }@args:
let
  currentDir = ./.;
  isDirectoryAndNotTemplate = name: type:
    type == "directory" && name != "templates";
  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
  importDirectory = name: import (currentDir + "/${name}") args;
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;
}
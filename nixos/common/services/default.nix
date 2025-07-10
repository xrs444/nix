{ lib, ... } @ args:
let
  currentDir = ./.;
  isDirectoryAndNotTemplate = name: type: type == "directory";
  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
  importDirectory = name:
    let mod = import (currentDir + "/${name}");
    in if builtins.isFunction mod then mod args else mod;
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;
}
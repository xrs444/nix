{ lib, ... }:
let
  currentDir = ./.;
  isDirectoryAndNotTemplate = name: type: type == "directory" && name != "_template";
  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
in
{
  imports = lib.mapAttrsToList (name: _: currentDir + "/${name}") directories;
}
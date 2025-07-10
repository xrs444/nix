{ lib, ... }:
let
#  currentDir = ./.;
#  isDirectoryAndNotTemplate = name: type:
#    type == "directory" && name != "templates";
#  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
#  importDirectory = name: currentDir + "/${name}/default.nix";
  defaultNixFiles = lib.filesystem.listFilesRecursive ./.;
  moduleFiles = builtins.filter (file: lib.hasSuffix "/default.nix" file) defaultNixFiles;
in
{
#  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;
  imports = moduleFiles;
}
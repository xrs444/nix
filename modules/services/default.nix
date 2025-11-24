{ lib, ... }:
let
  currentDir = ./.; # Represents the current directory
  isDirectoryAndNotTemplate = name: type: type == "directory" && name != "_template" && name != "letsencrypt" && name != "zfs";
  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
  importDirectory = name: (
    let path = currentDir + "/${name}";
    in
      builtins.trace ("Importing service module: " + toString path) (import path)
  );
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;
}
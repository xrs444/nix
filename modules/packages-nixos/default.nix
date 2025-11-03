{ config, lib, pkgs, ... }:

let
  currentDir = ./.; # Represents the current directory
  isDirectoryAndNotTemplate = name: type: type == "directory" && name != "_template";
  directories = lib.filterAttrs isDirectoryAndNotTemplate (builtins.readDir currentDir);
  importDirectory = name: import (currentDir + "/${name}");
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;

  # NixOS-specific packages
  environment.systemPackages = with pkgs; [
    # Add NixOS-specific packages here
  ];
}
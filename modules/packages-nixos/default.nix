{ config, lib, pkgs, ... }:

let
  kanidmServerUri = "https://idm.xrs444.net";
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
    
  services.kanidm = {
    enableClient = lib.mkDefault true;
      clientSettings = {
        uri = kanidmServerUri;
        verify_ca = true;
      };
    };
}

{ config, lib, pkgs, ... }:


let
  kanidmServerUri = "https://idm.xrs444.net";
  currentDir = ./.; # Represents the current directory
  hasDefaultNix = name: type:
    type == "directory" &&
    (builtins.pathExists (currentDir + "/" + name + "/default.nix"));
  directories = lib.filterAttrs hasDefaultNix (builtins.readDir currentDir);
  importDirectory = name: (
    let path = currentDir + "/${name}";
        mod = import path;
    in
      builtins.trace (
        "DEBUG: Importing package module: " + toString path + "\nType: " +
        (if builtins.isAttrs mod then "ATTRSET: " + (builtins.toJSON (builtins.attrNames mod))
         else if builtins.isList mod then "LIST: " + (builtins.toJSON mod)
         else if builtins.isPath mod then "PATH: " + toString mod
         else if builtins.isFunction mod then "FUNCTION"
         else builtins.toJSON mod)
      ) mod
  );
in
{
  imports = [
    # All dynamic package imports commented out for binary search
    # lib.mapAttrsToList (name: _: importDirectory name) directories
  ];

  # NixOS-specific packages
  environment.systemPackages = with pkgs; [
  ];
    
  services.kanidm = {
    enableClient = lib.mkDefault true;
      clientSettings = {
        uri = kanidmServerUri;
        verify_ca = true;
      };
    };
}

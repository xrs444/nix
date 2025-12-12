# Summary: NixOS module for common packages, imports submodules and adds system-wide utilities.
{
  pkgs,
  lib,
  config,
  ...
}:

let
  currentDir = ./.;
  hasDefaultNix =
    name: type: type == "directory" && builtins.pathExists (currentDir + "/" + name + "/default.nix");
  directories = lib.filterAttrs hasDefaultNix (builtins.readDir currentDir);
  importDirectory = name: import (currentDir + "/${name}");
in
{
  imports = lib.mapAttrsToList (name: _: importDirectory name) directories;

  config = {
    environment.systemPackages = with pkgs; [
      openssl
      micro
      sops
      git
    ];
  };
}

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
      mod
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

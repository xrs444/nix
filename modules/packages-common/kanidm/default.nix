{ config, hostname, lib, pkgs, ... }:

let
  kanidmServerUri = "https://idm.xrs444.net";
  isDarwin = pkgs.stdenv.isDarwin;
  kanidmPackage = pkgs.kanidm;
in

  {
    environment.systemPackages = with pkgs; [
      kanidmPackage
    ];
  };


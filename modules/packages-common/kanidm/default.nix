# Summary: NixOS module for Kanidm client, installs Kanidm package and configures environment for Darwin and Linux.
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
  }


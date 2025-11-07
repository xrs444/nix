{ config, hostname, lib, pkgs, ... }:

let
  kanidmServerUri = "https://idm.xrs444.net";
  isDarwin = pkgs.stdenv.isDarwin;
  kanidmPackage = pkgs.kanidm;
in
lib.mkMerge [
  # Install kanidm package everywhere (NixOS and Darwin)
  {
    environment.systemPackages = with pkgs; [
      kanidmPackage
    ];
  }

  # Only set up Kanidm client service settings on NixOS (NOT on Darwin)
  (lib.mkIf (!isDarwin) {
    services.kanidm = {
      enableClient = true;
      clientSettings = {
        uri = kanidmServerUri;
        verify_ca = true;
      };
    };
  })
]

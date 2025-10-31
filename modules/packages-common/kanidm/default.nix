{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  kanidmServerUri = "https://idm.xrs444.net";
  isDarwin = pkgs.stdenv.isDarwin;
  kanidmPackage = pkgs.kanidm;
in
lib.mkMerge [
  # Common packages for all systems
  {
    environment.systemPackages = with pkgs; [
      kanidmPackage 
    ];
  }

  # Temporarily disable all Kanidm client services
  # (lib.mkIf (!isDarwin) {
  #   services.kanidm = {
  #     enableClient = true;
  #     clientSettings = {
  #       uri = kanidmServerUri;
  #       verify_ca = true;
  #     };
  #   };
  # })
]
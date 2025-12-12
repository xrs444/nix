{
  config,
  lib,
  pkgs,
  ...
}:

let
  kanidmServerUri = "https://idm.xrs444.net";

in
{

  services.kanidm = {
    enableClient = lib.mkDefault true;
    clientSettings = {
      uri = kanidmServerUri;
      verify_ca = true;
    };
  };
}

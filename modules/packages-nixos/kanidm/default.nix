{
  lib,
  pkgs,
  ...
}:

let
  kanidmServerUri = "https://idm.xrs444.net";

in
{

  services.kanidm = {
    client.enable = lib.mkDefault true;
    client.settings = {
      uri = kanidmServerUri;
      verify_ca = true;
    };
  };
}

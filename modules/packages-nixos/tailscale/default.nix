{
  config,
  hostname,
  lib,
  pkgs,
  username,
  ...
}:
{
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  tsClients = [
    "xtl1-t-nixos"
    "xlt1-t"
  ];
  enableTailscale = lib.elem hostname tsClients;

in

with lib;

{
  services.tailscale = mkIf enableTailscale (mkMerge [
    { enable = true; }
    # Only on NixOS hosts
    (mkIf (!isDarwin) {
      extraUpFlags = [
        "--operator=${username}"
        "--accept-routes"
      ];
      extraSetFlags = [
        "--operator=${username}"
        "--accept-routes"
      ];
    })
  ]);

  environment.systemPackages = lib.optionals (isWorkstation && enableTailscale) [ pkgs.trayscale ];
}

{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  tsClients = [
    "xtl1-t-nixos"
    "xlt1-t"
  ];
  enableTailscale = lib.elem "${hostname}" tsClients;

in

with lib;

{
  services.tailscale = mkMerge [
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
  ];

  environment.systemPackages = with pkgs; lib.optionals isWorkstation [ trayscale ];
}

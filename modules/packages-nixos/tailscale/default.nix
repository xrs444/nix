{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale-custom;
  hostname = config.networking.hostName;
  
  installOn = [
  ];
in

with lib;

{
  services.tailscale = [
      { enable = true; }
      # Only on NixOS hosts
      (lib.mkIf (!isDarwin) {
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

    environment.systemPackages = with pkgs;
      lib.optionals isWorkstation [ trayscale ];
  };
}






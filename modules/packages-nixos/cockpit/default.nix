{ config, lib, pkgs, ... }:

let
  # Get hostname from the system configuration
  hostname = config.networking.hostName;
  
  installOn = [
    "xsvr1"
  ];
in

{
  config = lib.mkIf (lib.elem hostname installOn) {
    services.cockpit = {
      enable = true;
      openFirewall = true; 
    };
  };
}
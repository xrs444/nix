{ config, lib, pkgs, ... }:

let
  cfg = config.services.cockpit-custom;
  # Get hostname from the system configuration
  hostname = config.networking.hostName;
  
  installOn = [
    "xsvr1"
  ];
in

with lib;

{
  options.services.cockpit-custom = {
    enable = mkOption {
      type = types.bool;
      default = lib.elem hostname installOn;
      description = "Enable custom Cockpit configuration";
    };
  };

  config = mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      openFirewall = true; 
    };
  };
}
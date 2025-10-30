{ config, lib, pkgs, ... }:

let
  cfg = config.services.comin-custom;
  hostname = config.networking.hostName;
  
  installOn = [
    # Add hostnames where comin should be installed
  ];
in

with lib;

{
  options.services.comin-custom = {
    enable = mkOption {
      type = types.bool;
      default = lib.elem hostname installOn;
      description = "Enable custom Comin configuration";
    };
  };

  config = mkIf cfg.enable {
    # Your comin configuration here
    environment.systemPackages = with pkgs; [
      # comin-related packages
    ];
  };
}

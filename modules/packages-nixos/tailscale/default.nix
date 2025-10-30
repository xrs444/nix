{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale-custom;
  hostname = config.networking.hostName;
  
  installOn = [
    "xtl1-t-nixos"
    "xlt1-t"
  ];
in

with lib;

{
  options.services.tailscale-custom = {
    enable = mkOption {
      type = types.bool;
      default = lib.elem hostname installOn;
      description = "Enable custom Tailscale configuration";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    environment.systemPackages = with pkgs; [
      # tailscale-related packages
    ];
  };
}
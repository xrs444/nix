{ config, lib, pkgs, ... }:

let
  cfg = config.services.comin-custom;
  hostname = config.networking.hostName;
  
in

with lib;

{
  options.services.comin-custom = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable custom Comin configuration";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      comin
    ];
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/xrs444/nix.git";
          branches.main.name = "main";
        }
      ];
    };
  };
}

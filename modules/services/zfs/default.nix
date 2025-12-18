# Summary: NixOS module for ZFS filesystem support, enables ZFS and configures environment for selected hosts.
{
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:
let
  hasRole = lib.elem "zfs" hostRoles;
in
lib.mkIf hasRole {
  boot.supportedFilesystems = [ "zfs" ];
  environment = {
    systemPackages = with pkgs; [ zfs ];
    etc = {
      "vm".source = "/zfs/vm";
      "vm".target = "/vm";
    };
  };
  services.zfs = {
    autoScrub.enable = true;
  };
  services.sanoid = {
    enable = true;
    datasets = {
      "zroot/persist" = {
        hourly = 50;
        daily = 15;
        weekly = 3;
        monthly = 1;
      };
    };
  };
}
// { }

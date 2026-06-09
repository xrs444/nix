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
{
  imports = [
    ./replication.nix
  ];

  config = lib.mkIf hasRole {
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;
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
    };
  };
}

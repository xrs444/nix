{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../common/hardware-intel.nix
    ./disks.nix
    ./network.nix
    ./vms.nix
  ];

  boot = {
    zfs.extraPools = [ "zpool-xsvr2" ];    
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
      '';
    };
  };
}

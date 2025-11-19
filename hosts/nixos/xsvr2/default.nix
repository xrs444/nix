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
    ../common/boot.nix
    ../common/performance.nix
    ./disks.nix
    ./network.nix
    ./vms.nix
    # Only import letsencrypt if not minimal
    (lib.optional (!config.minimalImage) ../../../../modules/services/letsencrypt)
    # Add other heavy modules here as needed
  ];

  networking.hostName = hostname;

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

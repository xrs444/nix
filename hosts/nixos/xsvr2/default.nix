{ config, lib, inputs, hostname, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./vms.nix
    ../../../../modules/services/zfs
    ./disks.nix
    inputs.disko.nixosModules.disko
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

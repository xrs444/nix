{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./vms.nix
    ../../../modules/services/zfs
    ./disks.nix
  ];
  # Add other heavy modules here as needed

  networking = {
    hostName = hostname;
    hostId = "8f9996ca";
    useNetworkd = true;
  };

  boot = {
    zfs.extraPools = [ "zpool-xsvr2" ];
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
      '';
    };
  };
  nixpkgs.config.allowUnfree = true;
}

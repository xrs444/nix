{
  config,
  lib,
  pkgs,
  hostname,
  inputs,
  username,
  platform,
  ...
}:
{
  imports = [
    (import (inputs.self + /modules/packages-common/default.nix))
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./vms.nix
    ./disks.nix
    (import (inputs.self + /modules/services/default.nix) { inherit config lib pkgs; })
  ];

  # Add other heavy modules here as needed

  networking.hostName = hostname;
  networking.hostId = "8f9996ca";
  networking.useNetworkd = true;

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

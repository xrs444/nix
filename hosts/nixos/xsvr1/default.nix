{ config, hostname, inputs, lib, pkgs, username, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/performance.nix
    ./disks.nix # must come before disko module
    ./network.nix
    ./vms.nix
    ../../../modules/services/zfs
    # Add other heavy modules here as needed
    inputs.disko.nixosModules.disko
  ];

  networking.hostName = hostname;


  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
        "nvme"
      ];
    };
    zfs.extraPools = [ "zpool-xsvr1" ];
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
        ARRAY /dev/md/root_fs level=raid1 num-devices=2 metadata=1.2 UUID=884cb28d:29034e8f:ceb18126:b576c244 devices=/dev/sde2,/dev/sdf2
      '';
    };
  };

  nix.settings.trusted-users = [ "root" "builder" ];
  nixpkgs.config.allowUnfree = true;
}


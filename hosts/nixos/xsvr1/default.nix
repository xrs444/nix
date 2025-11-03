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
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/performance.nix
    ./disks.nix
    ./network.nix
    ./vms.nix
  ];

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
  
}

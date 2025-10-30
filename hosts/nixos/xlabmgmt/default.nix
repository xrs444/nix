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
    ../common/vm-guest.nix
    ./disks.nix
#    ./network.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
      ];
    };
  };

}

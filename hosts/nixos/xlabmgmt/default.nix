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
    ../common/vm-guest.nix
    ./disks.nix
    ./desktop.nix
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

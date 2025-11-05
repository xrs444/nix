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
    ../common/boot.nix
    ./disks.nix
#    ./network.nix
  ];

  networking.hostName = hostname;

  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
      ];
    };
  };

}
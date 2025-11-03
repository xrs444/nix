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
    ./desktop.nix
    ./serial.nix
    ./vms.nix
  ];

}


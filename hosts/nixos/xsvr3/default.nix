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
    ./disks.nix
    ./network.nix
    ./desktop.nix
    ./serial.nix
    ./vms.nix
  ];

}


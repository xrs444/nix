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
    ../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./disks.nix
    ./network.nix
    ./desktop.nix
    ./serial.nix
    ./vms.nix
    # Only import letsencrypt if not minimal
    (lib.optional (!config.minimalImage) ../../../../modules/services/letsencrypt)
    # Add other heavy modules here as needed
  ];

  networking.hostName = hostname;

}


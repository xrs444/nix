{ config, lib, inputs, hostname, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/vm-guest.nix
    ./desktop.nix
#    ./network.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
    # Add other heavy modules here as needed
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
      ];
    };
  };
}

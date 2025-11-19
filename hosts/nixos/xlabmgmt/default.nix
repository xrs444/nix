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
    # Only import letsencrypt if not minimal
    (lib.optional (!config.minimalImage) ../../../../modules/services/letsencrypt)
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

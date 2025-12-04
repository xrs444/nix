{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  config,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/boot.nix
    ./disks.nix
    #    ./network.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  networking.hostName = hostname;

  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
}

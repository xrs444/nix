# Summary: NixOS ARM host configuration for xts2, imports boot and disk modules.
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
    ../common/performance.nix
    ./disks.nix
    #    ./network.nix
    ../../common
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

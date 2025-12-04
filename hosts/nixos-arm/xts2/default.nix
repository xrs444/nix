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
    (import (inputs.self + /modules/packages-common/default.nix))
    ../../base-nixos.nix
    ../common/boot.nix
    ./disks.nix
    #    ./network.nix
    (import (inputs.self + /modules/services/default.nix) { inherit config lib pkgs; })
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

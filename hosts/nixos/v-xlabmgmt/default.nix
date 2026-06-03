# Summary: NixOS host configuration for v-xlabmgmt VM, imports boot, VM guest, desktop, and disk modules.
{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/boot.nix
    ../common/vm-guest.nix
    ./desktop.nix
    ./network.nix
    ./disks.nix
    ../../common
  ];

  networking.hostName = hostname;

  # VM guest — no physical AMD hardware modules needed
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
}

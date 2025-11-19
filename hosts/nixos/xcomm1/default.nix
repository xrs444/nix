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
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./disks.nix
    ./network.nix
    ./desktop.nix
    # Only import letsencrypt if not minimal
    (lib.optional (!config.minimalImage) ../../../../modules/services/letsencrypt)
    # Add other heavy modules here as needed
  ];
}
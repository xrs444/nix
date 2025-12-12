# Summary: Minimal SD image configuration for xts1, bootstraps with comin for full config deployment.
{
  pkgs,
  lib,
  stateVersion,
  hostname,
  username,
  ...
}:
let
  disksPath = ./disks.nix;
  hasDisksConfig = builtins.pathExists disksPath;
in
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-arm64-server.nix
    ../common/boot.nix
    ../../../modules/sdImage/custom.nix
  ]
  ++ lib.optional hasDisksConfig disksPath;
  system.stateVersion = stateVersion;
  networking.hostName = hostname;

  # Basic user configuration
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = lib.mkDefault pkgs.bash;
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Boot configuration handled by sd-image.nix and hardware modules
}

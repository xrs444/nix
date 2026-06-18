# Summary: Minimal installer image for vocibuild (Oracle Cloud A1 Flex aarch64).
# Note: ARM minimal configs include sd-image.nix from mkMinimalNixosConfig — this is
# a placeholder so the flake evaluates; actual deployment uses nixos-anywhere, not SD images.
{
  pkgs,
  lib,
  stateVersion,
  hostname,
  username,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-arm64-server.nix
    ../common/boot.nix
    ./disks.nix
    ../../../modules/sdImage/custom.nix
  ];

  system.stateVersion = stateVersion;
  networking.hostName = hostname;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = lib.mkDefault pkgs.bash;
  };

  security.sudo.wheelNeedsPassword = lib.mkForce false;
}

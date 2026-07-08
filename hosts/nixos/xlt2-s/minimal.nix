# Summary: Minimal installer configuration for xlt2-s; deploy with deploy-rs after boot.
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
    ../common/hardware-amd.nix
    ../common/boot.nix
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

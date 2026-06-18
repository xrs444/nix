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
    ./disks.nix
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

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

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;
}

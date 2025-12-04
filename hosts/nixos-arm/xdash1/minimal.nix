{
  pkgs,
  stateVersion,
  hostname,
  inputs,
  ...
}:
assert hostname != null && hostname != "";

{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    (import (inputs.self + /modules/hardware/OrangePiZero3/default.nix))
    ../common/boot.nix
    (import (inputs.self + /modules/sdImage/custom.nix))
  ];

  # Optionally override or add minimal-only options here
  environment.systemPackages = with pkgs; [ labwc ];
  system.stateVersion = stateVersion;

  networking.hostName = hostname;

  minimalImage = true;

  users.users.xdash1 = {
    isNormalUser = true;
    home = "/home/xdash1";
    createHome = true;
    shell = pkgs.bashInteractive;
    group = "xdash1";
  };

  users.groups.xdash1 = { };

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;
  boot.supportedFilesystems = [
    "vfat"
    "ext4"
  ];
}

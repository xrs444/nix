{ pkgs, hostname, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/packages-nixos/bootstrap/minimal.nix
  ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = hostname;
  networking.hostId = "0814bb9a";
  networking.useNetworkd = true;
}

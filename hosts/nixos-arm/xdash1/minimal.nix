{ pkgs, ... }:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-orangepi.nix
    ../common/boot.nix
    ./disks.nix
    ../../../modules/packages-nixos/bootstrap/minimal.nix
  ];

  # Optionally override or add minimal-only options here
  environment.systemPackages = with pkgs; [ labwc ];
}

# Summary: NixOS ARM host configuration for xhac-radio, imports hardware, boot, network, and SD image modules.
{
  hostname,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    ../common/boot.nix
    ./network.nix
    ./socat.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    # Common imports are now handled by hosts/common/default.nix
  ];

  networking.hostName = hostname;

  # To build a bootable SD image for this host, run:
  # nix build .#nixosConfigurations.xhac-radio.config.system.build.sdImage
  nixpkgs.config.allowUnfree = true;
}

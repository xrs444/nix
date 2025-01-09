  { inputs, lib, ... }:

{
  imports = [
    ./disks.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];
  hardware.cpu.amd.updateMicrocode = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

}
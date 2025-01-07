  { inputs, lib, ... }:

{
  imports = [
    ./disks.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];
  hardware.cpu.amd.updateMicrocode = true;
  nixpkgs.hostPlatform = "x86_64-linux";


}
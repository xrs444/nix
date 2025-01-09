{ inputs, lib, ... }:

{
  imports = [
    (import ./disks.nix { inherit lib; })
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-pc
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = true;

}
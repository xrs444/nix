{
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    ./disks.nix
    ./network.nix
    ./vms.nix
  ];
  hardware.cpu.amd.updateMicrocode = true;
  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader.systemd-boot.enable = true;
    kernel.sysctl."net.ipv4.ip_forward" = 1;
    initrd = {
      availableKernelModules = [
        "mpt3sas"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "nvme"
      ];
      kernelModules = [
        "kvm-amd"
        "amdgpu"
      ];
    };
    zfs.extraPools = [ "zpool-xsvr1" ];
    swraid = {
      enable = true;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  

}

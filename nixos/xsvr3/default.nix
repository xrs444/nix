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
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./disks.nix
    ./network.nix
    ./desktop.nix
    ./serial.nix
    ./vms.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader.systemd-boot.enable = true;
    kernel.sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
    kernel.sysctl."net.ipv4.proxy_arp" = lib.mkForce 1;

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod" 
      ];
      kernelModules = [
        "kvm-intel" 
      ];
    };    
  };

  powerManagement.cpuFreqGovernor = "performance";
}

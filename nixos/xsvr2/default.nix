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
    ./vms.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader.systemd-boot.enable = true;
    kernel.sysctl."net.ipv4.ip_forward" = 1;
#    kernel.sysctl."net.ipv4.conf.all.proxy_arp" = 1;
    kernel.sysctl."net.ipv4.conf.arp_ignore" = 1;
    kernel.sysctl."net.ipv4.conf.arp_announce" = 1;

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
    zfs.extraPools = [ "zpool-xsvr2" ];    
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
      '';
    };
  };
  powerManagement.cpuFreqGovernor = "performance";
}

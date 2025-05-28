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
#    kernel.sysctl."net.ipv4.conf.all.proxy_arp" = 1;
    kernel.sysctl."net.ipv4.conf.arp_ignore" = 1;
    kernel.sysctl."net.ipv4.conf.arp_announce" = 1;
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
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
        ARRAY /dev/md/root_fs level=raid1 num-devices=2 metadata=1.2 UUID=884cb28d:29034e8f:ceb18126:b576c244 devices=/dev/sde2,/dev/sdf2
      '';
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  

}

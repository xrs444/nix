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
    inputs.nixos-hardware.nixosModules.common-pc
    ./disks.nix
    ./network.nix
    ./desktop.nix
  ];

  hardware = {
    cpu.amd.updateMicrocode = true;
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
    };

  };
  
  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    blacklistedKernelModules=["nouveau"];
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "nvme"
      ];
      kernelModules = [
        "kvm-amd"
        "nvidia"
      ];
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";


  services.xserver.videoDrivers = [ 
    "nvidia"
  ];
}

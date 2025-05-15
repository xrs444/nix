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
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc
    ./disks.nix
    ./network.nix
  ];

  hardware = {
    cpu.amd.updateMicrocode = true;
    graphics.enable = true;
#    nvidia = {
#      open = true;
#      modesetting.enable = true;
#      nvidiaSettings.enable = true;
#      powerManagement.enable = true;
#      package = pkgs.linuxPackages.nvidiaPackages.stable;
#   };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
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
        "amdgpu"
      ];
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";

  services.xserver.videoDrivers = [ 
#    "nvidia"
    "amdgpu"
  ];

}
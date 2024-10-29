{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: 
{
  imports = [
    inputs.determinate.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./nixos/modules/apps
    ./nixos/modules/services
    ./${hostname}
    ./hardware-configuration.nix
  ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "uas"
      "usbhid"
      "sd_mod"
      "xhci_pci"
    ];
    kernelModules = [
      "kvm-amd"
    ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
    };
  };

  users.users = {

    thomas-local = {
      initialPassword = "SoItBegins";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = ["wheel" "libvirtd"];
    };
  };
    
  }

# Summary: NixOS host configuration for xsvr3, imports hardware, boot, desktop, and VM modules.
{
  inputs,
  hostname,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    #    ./desktop.nix
    ./serial.nix
    ./vms.nix
    ./disks.nix
    ../../common
  ];

  boot.initrd = {
    availableKernelModules = [
      "mpt3sas"
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "dm_mod"
    ];
  };

  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
}

# Summary: NixOS host configuration for xsvr3, imports hardware, boot, desktop, and VM modules.
{
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

  # Builder-specific GC: daily schedule + automatic free-space trigger.
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.settings = {
    min-free = 10737418240;  # 10 GiB
    max-free = 53687091200;  # 50 GiB
  };
}

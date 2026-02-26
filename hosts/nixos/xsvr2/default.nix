# Summary: NixOS host configuration for xsvr2, imports hardware, boot, VM, and disk modules.
{
  hostname,
  inputs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./replication.nix
    ./vms.nix
    ./disks.nix
    ../../common
  ];

  # Add other heavy modules here as needed

  networking.hostName = hostname;
  networking.hostId = "8f9996ca";
  networking.useNetworkd = true;

  boot = {
    initrd = {
      availableKernelModules = [
        "mpt3sas"
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "dm_mod"
        "raid1"
        "md_mod"
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
  nixpkgs.config.allowUnfree = true;
}

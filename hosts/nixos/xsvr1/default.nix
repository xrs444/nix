# Summary: NixOS host configuration for xsvr1, imports hardware, boot, disk, network, and VM modules.
{
  inputs,
  hostname,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../../common
    ../common/hardware-amd.nix
    ../common/boot.nix
    ../common/performance.nix
    ./disks.nix
    ./network.nix
    ./shares.nix
    ./vms.nix
  ];

  networking.hostName = hostname;
  networking.hostId = "0814bb9a";
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
    zfs.extraPools = [ "zpool-xsvr1" ];
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
        ARRAY /dev/md/root_fs level=raid1 num-devices=2 metadata=1.2 UUID=884cb28d:29034e8f:ceb18126:b576c244 devices=/dev/sde2,/dev/sdf2
      '';
    };
  };

  nix.settings.trusted-users = [
    "root"
    "builder"
  ];
  nixpkgs.config.allowUnfree = true;
}

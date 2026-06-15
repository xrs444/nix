# Summary: NixOS host configuration for xsvr2, imports hardware, boot, VM, and disk modules.
{
  lib,
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
    ./replication.nix
    ./offsite-backup.nix
    ./vms.nix
    ./disks.nix
    ../../common
  ];

  # Add other heavy modules here as needed

  networking.hostName = hostname;
  networking.hostId = "8f9996ca";
  networking.useNetworkd = true;
  # Temporary: Add nixcache to hosts for troubleshooting DNS issues
  networking.hosts = {
    "172.20.1.10" = [ "nixcache.xrs444.net" ];
  };

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
    zfs.extraPools = [
      "zpool-xsvr2"
      "zpool-xsvr2-media"
    ];
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
      '';
    };
  };
  nixpkgs.config.allowUnfree = true;

  # Builder-specific GC: daily schedule + automatic free-space trigger.
  # Weekly GC (base-nixos.nix) is too infrequent for a remote builder —
  # failed builds accumulate quickly and exhaust disk, causing spurious
  # ENOSPC failures on legitimate subsequent builds.
  nix.gc = {
    automatic = true;
    dates = lib.mkForce "daily";
    options = lib.mkForce "--delete-older-than 7d";
  };
  nix.settings = {
    # Trigger GC automatically if store drops below 10 GiB free,
    # stopping once 50 GiB is reclaimed. Fires mid-build if needed.
    min-free = 10737418240;  # 10 GiB
    max-free = 53687091200;  # 50 GiB
  };
}

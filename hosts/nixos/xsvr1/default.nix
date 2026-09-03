# Summary: NixOS host configuration for xsvr1, imports hardware, boot, disk, network, and VM modules.
{
  inputs,
  hostname,
  lib,
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
    ./replication.nix
    ./shares.nix
    ./tape-backup.nix
    ./vms.nix
  ];

  networking.hostName = hostname;
  networking.hostId = "0814bb9a";
  networking.useNetworkd = true;

  boot = {
    # Cap ZFS ARC at 24GiB (default is ~all RAM). Uncapped, ARC competes with
    # v-k8s-xsvr1's 24GiB libvirt allocation (vms.nix) for this host's 64GiB —
    # already seeing zram swap usage under normal load without a cap.
    extraModprobeConfig = ''
      options zfs zfs_arc_max=25769803776
    '';
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
    zfs.extraPools = [ "zpool-xsvr1-main" ];
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
        ARRAY /dev/md/root_fs level=raid1 num-devices=2 metadata=1.2 UUID=884cb28d:29034e8f:ceb18126:b576c244 devices=/dev/disk/by-id/ata-CT1000BX500SSD1_2432E8BE03BE-part2,/dev/disk/by-id/ata-CT1000BX500SSD1_2434E9882FC2-part2
      '';
    };
  };

  # Note: Using trusted-substituters instead of trusted-users for better security
  # See modules/services/remotebuilds/default.nix for trusted-substituters configuration
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    inputs.deploy-rs.packages.x86_64-linux.deploy-rs
  ];

  # Builder-specific GC: daily schedule + automatic free-space trigger.
  # Weekly GC (base-nixos.nix) is too infrequent for a remote builder —
  # failed builds accumulate quickly and exhaust disk, causing spurious
  # ENOSPC failures on legitimate subsequent builds. Same pattern as
  # xsvr2/xsvr3/vocibuild. xsvr1 is also part of the builder pool
  # (modules/services/remotebuilds/default.nix) and the CI runner itself,
  # so it churns build sandboxes constantly.
  nix.gc = {
    automatic = true;
    dates = lib.mkForce "daily";
    options = lib.mkForce "--delete-older-than 7d";
  };
  nix.settings = {
    # Trigger GC automatically if store drops below 10 GiB free,
    # stopping once 50 GiB is reclaimed. Fires mid-build if needed.
    min-free = 10737418240; # 10 GiB
    max-free = 53687091200; # 50 GiB
  };
}

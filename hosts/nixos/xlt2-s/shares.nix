{
  # On-demand NFS automounts of xsvr1 ingest drop folders.
  # noauto + x-systemd.automount: mounts trigger on first access, unmount after 10 min idle.
  # nofail on all shares: this is a laptop on WiFi, so a failed/timed-out mount
  # must never block boot. device uses xsvr1.lan (main LAN) rather than xsvr1's
  # VLAN-22 NFS IP (172.20.3.201) since that VLAN isn't guaranteed reachable
  # from WiFi — xsvr1.lan is the same hostname already used for SSH/Samba/nixcache
  # elsewhere in this repo, and xsvr1's NFS exports already permit 172.20.0.0/16,
  # which covers the main LAN too, so no server-side export change was needed.
  fileSystems = let
    ingest = sub: {
      device = "xsvr1.lan:/export/zfs/ingest/${sub}";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" "rw" "soft" "timeo=30"
        "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "nofail"
      ];
    };
  in {
    "/mnt/xsvr1/ingest/documents" = ingest "documents";
    "/mnt/xsvr1/ingest/ebooks"    = ingest "ebooks";
    "/mnt/xsvr1/ingest/3dmodels"  = ingest "3dmodels";
    "/mnt/xsvr1/ingest/games"     = ingest "games";
    "/mnt/xsvr1/ingest/movies"    = ingest "movies";
    "/mnt/xsvr1/ingest/tvshows"   = ingest "tvshows";
    "/mnt/xsvr1/ingest/music"     = ingest "music";
    "/mnt/xsvr1/scans" = {
      device = "xsvr1.lan:/export/zfs/scan/scans";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" "rw" "soft" "timeo=30"
        "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "nofail"
      ];
    };
    # Read-only distribution share (fonts, wallpaper, etc.) — see nix/hosts/nixos/xsvr1/shares.nix.
    "/mnt/xsvr1/distribute/fonts" = {
      device = "xsvr1.lan:/zfs/distribute/fonts";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" "ro" "soft" "timeo=30"
        "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "nofail"
      ];
    };
    "/mnt/xsvr1/distribute/wallpaper" = {
      device = "xsvr1.lan:/zfs/distribute/wallpaper";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" "ro" "soft" "timeo=30"
        "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "nofail"
      ];
    };
  };
}

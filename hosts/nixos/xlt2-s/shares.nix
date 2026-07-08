{
  # On-demand NFS automounts of xsvr1 ingest drop folders.
  # noauto + x-systemd.automount: mounts trigger on first access, unmount after 10 min idle.
  fileSystems = let
    ingest = sub: {
      device = "172.20.3.201:/zfs/ingest/${sub}";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" "rw" "soft" "timeo=30"
        "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"
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
      device = "172.20.3.201:/zfs/scan/scans";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" "rw" "soft" "timeo=30"
        "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600"
      ];
    };
  };
}

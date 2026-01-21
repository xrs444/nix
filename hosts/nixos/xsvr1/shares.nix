{
  config,
  pkgs,
  lib,
  ...
}:

{

  services.nfs.server = {
    enable = true;
    createMountPoints = lib.mkForce false;
    exports = ''
      /export 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash,fsid=0)
      /export/zfs/systembackups/longhorn 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/devicebackups 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/documents/manyfold 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/ingest 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/movies 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/tvshows 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # Create the bind mounts
  systemd.mounts = [
    {
      what = "/zfs/systembackups/longhorn";
      where = "/export/zfs/systembackups/longhorn";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/devicebackups";
      where = "/export/zfs/devicebackups";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/documents/manyfold";
      where = "/export/zfs/documents/manyfold";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/ingest";
      where = "/export/zfs/media/ingest";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/movies";
      where = "/export/zfs/media/movies";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/tvshows";
      where = "/export/zfs/media/tvshows";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Ensure export directory structure exists
  system.activationScripts.nfs4-export = ''
    mkdir -p /export/zfs/systembackups/longhorn
    mkdir -p /export/zfs/devicebackups
    mkdir -p /export/zfs/documents/manyfold
    mkdir -p /export/zfs/media/ingest
    mkdir -p /export/zfs/media/movies
    mkdir -p /export/zfs/media/tvshows

    # Ensure /zfs/devicebackups has correct ownership for BorgWarehouse (UID 1001)
    chown -R 1001:1001 /zfs/devicebackups
    chmod 755 /zfs/devicebackups
  '';

  services.nfs.settings = {
    nfsd = {
      "vers4" = "y";
      "vers4.0" = "y";
      "vers4.1" = "y";
      "vers4.2" = "y";
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        security = "user";
      };
      "public" = {
        "path" = "/mnt/Shares/Public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "username";
        "force group" = "groupname";
      };
      "private" = {
        "path" = "/mnt/Shares/Private";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "username";
        "force group" = "groupname";
      };
      "tm_xlt1-t" = {
        "path" = "/zfs/timemachine/xlt1-t";
        "valid users" = "xrs444";
        "public" = "no";
        "writeable" = "yes";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
      "longhorn-backups" = {
        "path" = "/zfs/systembackups/longhorn";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

}

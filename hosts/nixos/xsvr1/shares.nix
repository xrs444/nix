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
      /export/zfs/media/audiobooks/fiction 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/audiobooks/non-fiction 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/audiobooks/adult 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/system/crafty 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/systembackups/crafty 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/fiction 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/nonfiction 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/adult 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/system/matrix 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
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
      what = "/zfs/documents/photos";
      where = "/export/zfs/documents/photos";
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
    {
      what = "/zfs/media/audiobooks/fiction";
      where = "/export/zfs/media/audiobooks/fiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/audiobooks/non-fiction";
      where = "/export/zfs/media/audiobooks/non-fiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/audiobooks/adult";
      where = "/export/zfs/media/audiobooks/adult";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/games";
      where = "/export/zfs/media/games";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/system/crafty";
      where = "/export/zfs/system/crafty";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/systembackups/crafty";
      where = "/export/zfs/systembackups/crafty";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/books/fiction";
      where = "/export/zfs/media/books/fiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/books/nonfiction";
      where = "/export/zfs/media/books/nonfiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/books/adult";
      where = "/export/zfs/media/books/adult";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/media/books/ingest";
      where = "/export/zfs/media/books/ingest";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/system/matrix";
      where = "/export/zfs/system/matrix";
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
    mkdir -p /export/zfs/documents/photos
    mkdir -p /export/zfs/media/ingest
    mkdir -p /export/zfs/media/movies
    mkdir -p /export/zfs/media/tvshows
    mkdir -p /export/zfs/media/audiobooks/fiction
    mkdir -p /export/zfs/media/audiobooks/non-fiction
    mkdir -p /export/zfs/media/audiobooks/adult
    mkdir -p /export/zfs/media/games
    mkdir -p /export/zfs/system/crafty
    mkdir -p /export/zfs/systembackups/crafty
    mkdir -p /export/zfs/media/books/fiction
    mkdir -p /export/zfs/media/books/nonfiction
    mkdir -p /export/zfs/media/books/adult
    mkdir -p /export/zfs/system/matrix

    # Ensure books directories exist on ZFS
    mkdir -p /zfs/media/books/fiction
    mkdir -p /zfs/media/books/nonfiction
    mkdir -p /zfs/media/books/adult
    mkdir -p /zfs/media/books/ingest
    mkdir -p /zfs/system/matrix

    # Ensure crafty directories have correct ownership (UID/GID 1000)
    chown -R 1000:1000 /zfs/system/crafty
    chown -R 1000:1000 /zfs/systembackups/crafty

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

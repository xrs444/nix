{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Samba passwords managed via sops — set automatically on every nixos-rebuild switch.
  # Kanidm does not store NTLM hashes, so Samba uses its own tdbsam passdb.
  # Linux session login still goes through Kanidm PAM (enablePam = true on xsvr1).
  sops.secrets.xrs444_smb_password        = { sopsFile = ../../../secrets/samba.yaml; };
  sops.secrets.samantha_smb_password      = { sopsFile = ../../../secrets/samba.yaml; };
  sops.secrets.rowan_smb_password         = { sopsFile = ../../../secrets/samba.yaml; };
  sops.secrets.greyson_smb_password       = { sopsFile = ../../../secrets/samba.yaml; };
  sops.secrets.scanner_smb_password       = { sopsFile = ../../../secrets/samba.yaml; };
  sops.secrets.homeassistant_smb_password = { sopsFile = ../../../secrets/samba.yaml; };

  # Scanner service account — exists only for Samba authentication (HP M281 printer)
  users.users.scanner = {
    isSystemUser = true;
    group = "scanner";
    shell = "${pkgs.shadow}/bin/nologin";
    description = "HP printer SMB service account";
  };
  users.groups.scanner = {};

  # Home Assistant service account — exists only for Samba authentication
  users.users.homeassistant = {
    isSystemUser = true;
    group = "homeassistant";
    shell = "${pkgs.shadow}/bin/nologin";
    description = "Home Assistant SMB service account";
  };
  users.groups.homeassistant = {};

  # Avahi (mDNS) — required for Samba to advertise the Time Machine share over Bonjour.
  # Without this, macOS won't discover tm_xlt1-t as a Time Machine destination.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  services.nfs.server = {
    enable = true;
    createMountPoints = lib.mkForce false;
    exports = ''
      /export 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
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
      /export/zfs/system/loki 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/systembackups/crafty 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/fiction 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/nonfiction 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/adult 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/books/ingest 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/system/matrix 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/users/syncthing 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/media/music 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/ebooks 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/documents 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/3dmodels 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/games 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/movies 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/tvshows 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/ingest/music 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /export/zfs/scan/scans 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
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
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/documents/photos";
      where = "/export/zfs/documents/photos";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/ingest";
      where = "/export/zfs/media/ingest";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/movies";
      where = "/export/zfs/media/movies";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/tvshows";
      where = "/export/zfs/media/tvshows";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/audiobooks/fiction";
      where = "/export/zfs/media/audiobooks/fiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/audiobooks/non-fiction";
      where = "/export/zfs/media/audiobooks/non-fiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/audiobooks/adult";
      where = "/export/zfs/media/audiobooks/adult";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/games";
      where = "/export/zfs/media/games";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/system/crafty";
      where = "/export/zfs/system/crafty";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/system/loki";
      where = "/export/zfs/system/loki";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/systembackups/crafty";
      where = "/export/zfs/systembackups/crafty";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/books/fiction";
      where = "/export/zfs/media/books/fiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/books/nonfiction";
      where = "/export/zfs/media/books/nonfiction";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/books/adult";
      where = "/export/zfs/media/books/adult";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/books/ingest";
      where = "/export/zfs/media/books/ingest";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/system/matrix";
      where = "/export/zfs/system/matrix";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
    }
    {
      what = "/zfs/users/syncthing";
      where = "/export/zfs/users/syncthing";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/media/music";
      where = "/export/zfs/media/music";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    # ---- Ingest bind mounts ----
    {
      what = "/zfs/ingest/ebooks";
      where = "/export/zfs/ingest/ebooks";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/ingest/documents";
      where = "/export/zfs/ingest/documents";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/ingest/3dmodels";
      where = "/export/zfs/ingest/3dmodels";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/ingest/games";
      where = "/export/zfs/ingest/games";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/ingest/movies";
      where = "/export/zfs/ingest/movies";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/ingest/tvshows";
      where = "/export/zfs/ingest/tvshows";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/ingest/music";
      where = "/export/zfs/ingest/music";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
    {
      what = "/zfs/scan/scans";
      where = "/export/zfs/scan/scans";
      type = "none";
      options = "bind";
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
    }
  ];

  # Ensure export directory structure exists
  system.activationScripts.nfs4-export = {
    deps = [ "setupSecrets" ];
    text = ''
      mkdir -p /export/zfs/systembackups/longhorn
      mkdir -p /zfs/systembackups/homeassistant
      chown homeassistant:homeassistant /zfs/systembackups/homeassistant
      chmod 755 /zfs/systembackups/homeassistant
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
      mkdir -p /export/zfs/system/loki
      mkdir -p /zfs/system/loki
      chown 10001:10001 /zfs/system/loki
      chmod 755 /zfs/system/loki
      mkdir -p /export/zfs/systembackups/crafty
      mkdir -p /export/zfs/media/books/fiction
      mkdir -p /export/zfs/media/books/nonfiction
      mkdir -p /export/zfs/media/books/adult
      mkdir -p /export/zfs/media/books/ingest
      mkdir -p /export/zfs/system/matrix
      mkdir -p /export/zfs/media/music
      mkdir -p /export/zfs/ingest/ebooks
      mkdir -p /export/zfs/ingest/documents
      mkdir -p /export/zfs/ingest/3dmodels
      mkdir -p /export/zfs/ingest/games
      mkdir -p /export/zfs/ingest/movies
      mkdir -p /export/zfs/ingest/tvshows
      mkdir -p /export/zfs/ingest/music
      mkdir -p /export/zfs/scan/scans

      # Ensure ZFS directories exist (created by zfs create, but mkdir -p is a no-op if present)
      mkdir -p /zfs/media/books/fiction
      mkdir -p /zfs/media/books/nonfiction
      mkdir -p /zfs/media/books/adult
      mkdir -p /zfs/media/books/ingest
      mkdir -p /zfs/system/matrix
      mkdir -p /export/zfs/users/syncthing
      mkdir -p /zfs/users/syncthing
      mkdir -p /zfs/media/music
      mkdir -p /zfs/ingest/ebooks
      mkdir -p /zfs/ingest/documents
      mkdir -p /zfs/ingest/3dmodels
      mkdir -p /zfs/ingest/games
      mkdir -p /zfs/ingest/movies
      mkdir -p /zfs/ingest/tvshows
      mkdir -p /zfs/ingest/music
      mkdir -p /zfs/scan/scans

      # Ensure syncthing directory has correct ownership (UID/GID 1000)
      chown -R 1000:1000 /zfs/users/syncthing
      chmod 755 /zfs/users/syncthing

      # Ensure books directories have correct ownership and permissions for booklore (GID 1000)
      chown -R :1000 /zfs/media/books/fiction
      chown -R :1000 /zfs/media/books/nonfiction
      chown -R :1000 /zfs/media/books/adult
      chown -R :1000 /zfs/media/books/ingest
      chmod 775 /zfs/media/books/fiction
      chmod 775 /zfs/media/books/nonfiction
      chmod 775 /zfs/media/books/adult
      chmod 775 /zfs/media/books/ingest

      # Ensure crafty directories have correct ownership (UID/GID 1000)
      chown -R 1000:1000 /zfs/system/crafty
      chown -R 1000:1000 /zfs/systembackups/crafty

      # Ensure /zfs/devicebackups has correct ownership for BorgWarehouse (UID 1001)
      chown -R 1001:1001 /zfs/devicebackups
      chmod 755 /zfs/devicebackups

      # Ingest drop-box directories: world-writable + sticky bit (trusted LAN)
      chmod 1777 /zfs/ingest/ebooks /zfs/ingest/documents /zfs/ingest/3dmodels || true
      chmod 1777 /zfs/ingest/games /zfs/ingest/movies /zfs/ingest/tvshows /zfs/ingest/music || true
      chmod 1777 /zfs/scan/scans || true

      # Media library root dirs: owned by UID/GID 1000 (linuxserver abc user)
      # Radarr/Sonarr/Lidarr run as abc (1000:1000) and need write access to move files in.
      # Only chown the directory itself, not recursively, to avoid slowness on large libraries.
      chown 1000:1000 /zfs/media/movies /zfs/media/tvshows /zfs/media/music || true
      chmod 775 /zfs/media/movies /zfs/media/tvshows /zfs/media/music || true

      # Set Samba passwords from sops secrets (idempotent)
      set_smb_pass() {
        local user="$1"
        local passfile="$2"
        id "$user" &>/dev/null || return 0
        [ -f "$passfile" ] || return 0
        printf "%s\n%s\n" "$(cat "$passfile")" "$(cat "$passfile")" \
          | ${pkgs.samba}/bin/smbpasswd -a -s "$user" 2>/dev/null || true
        ${pkgs.samba}/bin/smbpasswd -e "$user" 2>/dev/null || true
      }
      set_smb_pass xrs444   ${config.sops.secrets.xrs444_smb_password.path} || true
      set_smb_pass samantha ${config.sops.secrets.samantha_smb_password.path} || true
      set_smb_pass rowan    ${config.sops.secrets.rowan_smb_password.path} || true
      set_smb_pass greyson  ${config.sops.secrets.greyson_smb_password.path} || true
      set_smb_pass scanner        ${config.sops.secrets.scanner_smb_password.path} || true
      set_smb_pass homeassistant  ${config.sops.secrets.homeassistant_smb_password.path} || true
    '';
  };

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
        # SMB2_02 required globally to support HP ColorLaserJet M281 scanner (uses
        # earliest SMB2 dialect). server min protocol is a global-only parameter in
        # Samba 4.x and cannot be overridden per-share.
        "server min protocol" = lib.mkForce "SMB2_02";
        # Extend base module's hosts allow to include Tailscale (100.64.0.0/10)
        "hosts allow" = lib.mkForce "172.16.0.0/12 100.64.0.0/10 127.0.0.1 localhost";
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
      "homeassistant-backups" = {
        "path" = "/zfs/systembackups/homeassistant";
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "homeassistant";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      # ---- Ingest shares (user-facing, also NFS-exported — oplocks disabled to prevent
      #      stale-cache races when NFS clients read files written via SMB) ----
      "ingest-ebooks" = {
        "path" = "/zfs/ingest/ebooks";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "ingest-documents" = {
        "path" = "/zfs/ingest/documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "ingest-3dmodels" = {
        "path" = "/zfs/ingest/3dmodels";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "ingest-games" = {
        "path" = "/zfs/ingest/games";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "ingest-movies" = {
        "path" = "/zfs/ingest/movies";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "ingest-tvshows" = {
        "path" = "/zfs/ingest/tvshows";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "ingest-music" = {
        "path" = "/zfs/ingest/music";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      # ---- Scanner shares (per-share SMB2_02 override for HP M281 compatibility) ----
      "scans" = {
        "path" = "/zfs/scan/scans";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "xrs444 samantha rowan greyson scanner";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
      "scans-paperless" = {
        # Points to the same path as ingest-documents — files dropped here are
        # immediately visible as Paperless-ngx consume folder input.
        "path" = "/zfs/ingest/documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "scanner xrs444 samantha rowan greyson";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

}

{ config, pkgs, lib, ...}: 

{

services.nfs.server = {
  enable = true;
  createMountPoints = true;
  exports = ''
    /export 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash,fsid=0)
    /export/zfs/systembackups/longhorn 172.21.0.0/24(rw,sync,no_subtree_check,no_root_squash) 172.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
  '';
};

# Create the bind mount
systemd.mounts = [
  {
    what = "/zfs/systembackups/longhorn";
    where = "/export/zfs/systembackups/longhorn";
    type = "none";
    options = "bind";
    wantedBy = [ "multi-user.target" ];
  }
];

# Ensure export directory structure exists
system.activationScripts.nfs4-export = ''
  mkdir -p /export/zfs/systembackups
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
  securityType = "user";
  openFirewall = true;
  settings = {
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
  };
      "tm_share" = {
        "path" = "/zfs/timemachine";
        "valid users" = "username";
        "public" = "no";
        "writeable" = "yes";
        "force user" = "username";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
    };
};

services.samba-wsdd = {
  enable = true;
  openFirewall = true;
};

}
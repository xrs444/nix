{ config, pkgs, lib, ...}: 

{

services.nfs.server.enable = true;

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
# Summary: NixOS module for Samba file sharing service, enables and configures Samba for selected hosts.
{
  hostRoles ? [ ],
  lib,
  ...
}:
let
  hasRole = lib.elem "samba" hostRoles;

in
{
  config = lib.mkIf hasRole {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "xrs444";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          #"use sendfile" = "yes";
          #"max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "172.16.0.0/12 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
      };
    };
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}

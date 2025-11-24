{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:
let
  installOn = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
  ];

in
{
  config = lib.mkIf (lib.elem "${hostname}" installOn) {
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
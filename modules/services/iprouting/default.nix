# Summary: NixOS module for IP routing, enables IP forwarding for selected hosts in the cluster.
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
    "xts1"
    "xrs2"
  ];
in
lib.mkIf (lib.elem "${hostname}" installOn) {

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
  };
}

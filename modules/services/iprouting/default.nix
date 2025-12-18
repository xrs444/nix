# Summary: NixOS module for IP routing, enables IP forwarding for selected hosts in the cluster.
{
  hostRoles ? [ ],
  lib,
  ...
}:
let
  hasRole = lib.elem "iprouting" hostRoles;
in
lib.mkIf hasRole {

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
  };
}

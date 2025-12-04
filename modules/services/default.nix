# Summary: Aggregates and imports all service modules for NixOS configuration.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./Samba
    ./bind
    ./ffr
    ./homeassistant
    ./iprouting
    ./kanidm
    ./keepalived
    ./kvm
    ./letsencrypt
    ./nfs
    ./nixcache
    ./openssh
    ./remotebuilds
    ./tailscale
    ./talos
    ./zfs
  ];
}

{ lib, ... }:
{
  imports = [
    # ./Samba
    # ./bind
    # ./ffr
    # ./homeassistant
    # ./iprouting
    # ./kanidm
    # ./keepalived
    # ./kvm
    # ./nfs
    # ./nixcache
    # ./openssh
    # ./remotebuilds
    # ./tailscale
    # ./talos
    # ./zfs and ./letsencrypt are imported explicitly elsewhere if needed
  ];
}
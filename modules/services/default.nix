# Summary: Aggregates and imports all service modules for NixOS configuration.
{ ... }:
{
  imports = [
    ./Samba
    ./bind
    ./borgbackup
    ./ffr
    ./homeassistant
    ./iprouting
    ./kanidm
    ./keepalived
    ./kvm
    ./letsencrypt
    ./monitoring
    ./nfs
    ./nixcache
    ./openssh
    ./remotebuilds
    ./ser2net
    ./socat
    ./tailscale
    ./talos
    ./vsftpd
    ./zfs
  ];
}

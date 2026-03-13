# Summary: Aggregates and imports all service modules for NixOS configuration.
{ ... }:
{
  imports = [
    ./Samba
    ./bind
    ./borgbackup
    ./determinate-nix
    ./ffr
    ./flakehub-auth
    ./github-runner
    ./homeassistant
    ./iprouting
    ./kanidm
    ./keepalived
    ./kvm
    ./letsencrypt
    ./monitoring
    ./nfs
    ./nixcache
    ./oauth2-proxy
    ./openssh
    ./remotebuilds
    ./reverse-proxy
    ./ser2net
    ./socat
    ./tailscale
    ./talos
    ./vsftpd
    ./zfs
  ];
}

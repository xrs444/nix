# Summary: Aggregates and imports all service modules for NixOS configuration.
{ ... }:
{
  imports = [
    ./Samba
    ./adguard
    ./auto-upgrade
    ./asterisk
    ./phone-config-nginx
    ./borgbackup
    ./determinate-nix
    ./bird-bgp
    ./flakehub-auth
    ./github-runner
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
    ./tftpd
    ./vsftpd
    ./zfs
  ];
}

# Static network configuration for xts1
# BGP/keepalived require stable IPs — xts1 is always 172.18.10.1
{ lib, ... }:
{
  # Override keepalived VRRP interface — RPi4 uses end0, not eth0
  # The tailscale module defaults eth0; override here to avoid hostname-comparison ambiguity
  services.keepalived.vrrpInstances.ts-vip.interface = lib.mkForce "end0";
  networking.useDHCP = false;

  networking.interfaces.end0 = {
    ipv4.addresses = [
      {
        address = "172.18.10.1";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "172.18.10.250";
    interface = "end0";
  };

  networking.nameservers = [ "172.18.10.250" ];

  # accept_ra=2: accept RAs even when all.forwarding=1 (set by tailscale exit-node role).
  # Without this, forwarding=1 causes the kernel to silently ignore RAs despite accept_ra=1.
  boot.kernel.sysctl."net.ipv6.conf.end0.accept_ra" = 2;
}

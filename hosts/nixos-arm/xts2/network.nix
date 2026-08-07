# Static network configuration for xts2
# BGP/keepalived require stable IPs — xts2 is always 172.18.10.2
# Interface: Amlogic DWMAC platform device typically stays eth0 on mainline Linux.
# Verify with `ip -brief addr` on first boot and update if different.
{ lib, ... }:
{
  networking.useDHCP = false;

  networking.interfaces.eth0 = {
    ipv4.addresses = [
      {
        address = "172.18.10.2";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "172.18.10.250";
    interface = "eth0";
  };

  networking.nameservers = [ "172.18.10.250" ];

  # xsvr1 (172.20.1.10) is the CI/build/deploy hub — it repeatedly connects
  # through this VIP pair (172.18.10.100, xts1/xts2 VRRP) as a Nix remote-build
  # ProxyJump hop and to deploy xts2 itself. See xts1/network.nix for the full
  # root-cause note — same fix applied to both VIP-pair members since either
  # can hold the VIP at ban time.
  services.fail2ban.ignoreIP = [ "172.20.1.10" ];

  # accept_ra=2: accept RAs even when all.forwarding=1 (set by tailscale exit-node role).
  # Without this, forwarding=1 causes the kernel to silently ignore RAs despite accept_ra=1.
  boot.kernel.sysctl."net.ipv6.conf.eth0.accept_ra" = 2;

  # keepalived VRRP interface — eth0 for Sweet Potato (Amlogic DWMAC)
  # Update to match actual interface name if it differs on first boot
  services.keepalived.vrrpInstances.ts-vip.interface = lib.mkForce "eth0";
}

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

  # xsvr1 (172.20.1.10) is the CI/build/deploy hub — it repeatedly connects here
  # as a Nix remote-build ProxyJump hop (builder@172.18.10.100) and to deploy
  # xts1 itself. A pubkey-auth fallback to keyboard-interactive (root cause
  # still unconfirmed — likely connection load/racing during CI's heavy
  # parallel build phase) intermittently trips fail2ban's sshd jail, banning
  # xsvr1 for 10m-40m+ (escalating) and blocking every host that routes
  # through this VIP, including vocibuild's deploy and xts1's own deploy —
  # confirmed via journalctl: a "Connection refused" from CI at 2026-08-06
  # 22:40 MST landed inside a confirmed 22:08:47-22:48:46 ban of 172.20.1.10.
  services.fail2ban.ignoreIP = [ "172.20.1.10" ];

  # accept_ra=2: accept RAs even when all.forwarding=1 (set by tailscale exit-node role).
  # Without this, forwarding=1 causes the kernel to silently ignore RAs despite accept_ra=1.
  boot.kernel.sysctl."net.ipv6.conf.end0.accept_ra" = 2;
}

# Static network configuration for xidm1 (formerly xts2)
# Re-IP'd onto the server VLAN (VLAN 20, 172.20.1.0/24) 2026-08-21 so Kanidm
# replication (port 8444) stays same-subnet as xsvr1/xsvr2, and so xidm1 can join the
# idm keepalived VIP (172.20.1.110) — see modules/services/keepalived/default.nix.
# Interface: Amlogic DWMAC platform device typically stays eth0 on mainline Linux.
# Verify with `ip -brief addr` on first boot and update if different.
{ ... }:
{
  networking.useDHCP = false;

  networking.interfaces.eth0 = {
    ipv4.addresses = [
      {
        address = "172.20.1.111";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "172.20.1.250";
    interface = "eth0";
  };

  networking.nameservers = [ "172.20.1.250" ];

  # xsvr1 (172.20.1.10) is the CI/build/deploy hub — it deploys xidm1 directly now
  # that both are on the server VLAN (no more VIP ProxyJump hop needed). Kept as a
  # precaution against the same fail2ban-bans-the-deploy-hub failure mode documented
  # on xsvr1/2/3 and the old xts1/xts2 pair.
  services.fail2ban.ignoreIP = [ "172.20.1.10" ];

  # eth0 is on VLAN 20 (server-core), which is ULA-only (fd66:150f:7361:0014::/64,
  # see docs/ipv6-addressing.md) — there is no real internet-routable IPv6 behind it,
  # but the Firewalla still advertises a default route via RA on it regardless
  # (bug-1063/1066, same mechanism fixed on xsvr1-4 via systemd-networkd's
  # UseGateway=false). This host uses the legacy scripted-networking stack instead of
  # systemd-networkd, so the equivalent is the kernel's own accept_ra_defrtr sysctl:
  # keeps SLAAC/on-link prefix info from RA, just doesn't install the phantom default
  # route. vlan10 (below) is the one interface meant to carry a real default route.
  boot.kernel.sysctl."net.ipv6.conf.eth0.accept_ra_defrtr" = 0;

  # VLAN 10 (172.18.10.0/24) is GUA-role on the Firewalla (stateless DHCPv6) — tagged
  # on top of eth0, IPv6-only: v4 egress already works fine via eth0's static gateway.
  # Needs the matching switch-side tag on xswcore (ethe 2/1/45, see playbook.yml).
  networking.vlans.vlan10 = {
    id = 10;
    interface = "eth0";
  };
}

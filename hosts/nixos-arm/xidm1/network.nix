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
}

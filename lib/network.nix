# Summary: Named network ranges shared across modules (N5) — one place to change when a
# VLAN/subnet is renumbered, instead of the same CIDR string repeated across files.
#
# Usage from a module/host file:   net = import ../../../lib/network.nix;   (adjust ../ depth)
# This is plain data (no dependencies), so it imports cleanly from anywhere.
#
# Only ranges that are repeated across modules belong here; per-host addresses (a host's
# own IP, its VIP priority, BGP peers) stay in that host/module's config.
{
  # Cilium LoadBalancer IP pool — Service VIPs (Traefik, samba-dc, crafty, ...). Not node IPs.
  ciliumLb = "172.21.0.0/24";

  # All k8s-side VLANs; a superset that covers the Talos nodes and e.g. xfw's gateway
  # address (172.20.3.250).
  k8s = "172.20.0.0/16";

  # Talos node subnet. In-cluster pods (e.g. Prometheus) are masqueraded to these node IPs
  # when talking to hosts outside the cluster, so this is the source address scrapes
  # arrive from.
  talosNodes = "172.20.3.0/24";

  # Tailscale CGNAT range.
  tailscale = "100.64.0.0/10";

  # Office/workstation VLAN 100 (wired office clients, e.g. xlt2-s).
  officeVlan = "172.18.100.0/24";

  # Phone VLAN — SIP phones identified by IP in asterisk pjsip.nix.
  phoneVlan = "172.18.6.0/24";

  # Home Assistant host; the PJSIP trunk (endpoint 801) to Asterisk. It sits outside the
  # phone VLAN, so SIP/RTP allow-lists need it explicitly.
  homeAssistant = "172.18.7.1/32";

  # 172.16.0.0/12 — covers every home VLAN (172.18.x, 172.20.x, 172.21.x, ...).
  homeVlans = "172.16.0.0/12";

  # 192.168.0.0/24 — the LAN allowed to use AdGuard on cmrpi1 (see modules/services/adguard).
  adguardLan = "192.168.0.0/24";
}

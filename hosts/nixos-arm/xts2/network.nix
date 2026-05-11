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

  # keepalived VRRP interface — eth0 for Sweet Potato (Amlogic DWMAC)
  # Update to match actual interface name if it differs on first boot
  services.keepalived.vrrpInstances.ts-vip.interface = lib.mkForce "eth0";
}

# Summary: Network configuration for xpbx1 - Uses DHCP; deployed via deploy-rs
{ ... }:
{
  networking = {
    # DHCP is handled explicitly by the systemd.network unit below for enu1u1u1;
    # useDHCP = false matches the other ARM hosts (cmrpi1/xts1/xts2) and avoids
    # conflicting with NetworkManager's own useDHCP=false in the minimal bootstrap image.
    useDHCP = false;
    useNetworkd = true;
  };

  # Simple DHCP configuration for initial boot
  systemd.network = {
    enable = true;
    networks = {
      "40-enu1u1u1" = {
        matchConfig.Name = "enu1u1u1";
        networkConfig.DHCP = "yes";
      };
    };
  };
}

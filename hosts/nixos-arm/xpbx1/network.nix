# Summary: Network configuration for xpbx1 - Uses DHCP; deployed via deploy-rs
{ ... }:
{
  networking = {
    # Use DHCP for initial network setup
    useDHCP = true;
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

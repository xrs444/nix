# Summary: Network configuration for xpbx1
{ ... }:
{
  networking = {
    # Use systemd-networkd for network configuration
    useNetworkd = true;
    useDHCP = false;

    # Default gateway for VoIP network
    defaultGateway = {
      address = "172.18.6.1";
      interface = "eth0";
    };

    # DNS servers
    nameservers = [
      "172.18.6.1"
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # Enable systemd-networkd with static IP
  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        matchConfig.Name = "eth0 en*";
        networkConfig = {
          Address = "172.18.6.1/24";
          Gateway = "172.18.6.1";
          DNS = [ "172.18.6.1" "1.1.1.1" "8.8.8.8" ];
        };
      };
    };
  };
}

# Summary: Network configuration for cmrpi1
{ ... }:
{
  networking = {
    # Use NetworkManager for easier network configuration
    networkmanager.enable = true;

    # Disable dhcpcd as NetworkManager handles DHCP
    useDHCP = false;

    # Allow DNS server to bind to all interfaces
    firewall.interfaces = {
      # Allow DNS queries on all network interfaces
      # Specific interface configuration can be added here if needed
    };
  };
}
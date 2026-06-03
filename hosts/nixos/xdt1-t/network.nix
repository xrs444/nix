{ lib, ... }:
{
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # TODO: pin a static IP and set the wired NIC name after first boot.
  # Example (if NIC is enp6s0):
  # networking.useDHCP = false;
  # networking.interfaces.enp6s0.ipv4.addresses = [{
  #   address = "172.18.X.X";
  #   prefixLength = 24;
  # }];
  # networking.defaultGateway = "172.18.X.1";
  # networking.nameservers = [ "172.18.10.250" ];
}

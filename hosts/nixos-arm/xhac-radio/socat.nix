# Summary: Socat configuration for xhac-radio - forwards USB Zwave/Zigbee radios to Home Assistant VM
{ ... }:
{
  # Enable socat for USB device forwarding to Home Assistant VM
  # Forwards Zwave and Zigbee USB radios over network
  services.socat = {
    enable = true;
    instances = {
      # Example: Forward Zwave USB device to Home Assistant
      # Uncomment and configure with actual device paths and ports:
      # zwave-radio = {
      #   source = "TCP-LISTEN:8888,fork,reuseaddr";
      #   destination = "/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_C1302F8F-if00-port0,raw,echo=0";
      #   options = [ "-d" "-d" ];  # Verbose logging
      #   user = "root";  # USB device access typically requires root
      #   group = "dialout";
      # };

      # Example: Forward Zigbee USB device to Home Assistant
      # zigbee-radio = {
      #   source = "TCP-LISTEN:8889,fork,reuseaddr";
      #   destination = "/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_C1302F8F-if01-port0,raw,echo=0";
      #   options = [ "-d" "-d" ];
      #   user = "root";
      #   group = "dialout";
      # };
    };
  };
}

# Summary: Ser2net configuration for xhac-radio - presents USB Zwave/Zigbee radios to Home Assistant VM
{ ... }:
{
  # Enable ser2net for USB device forwarding to Home Assistant VM
  # Presents Zwave and Zigbee USB radios over network
  services.ser2net = {
    enable = false; # Set to true and configure device below
    # Configure with actual device paths and ports:
    # Example for Zwave radio:
    # port = 8888;
    # device = "/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_C1302F8F-if00-port0";
    # baudrate = 115200;
  };
}

# Summary: Ser2net configuration for xhac-radio - presents USB Zwave/Zigbee radios to Home Assistant VM
{ pkgs, ... }:
{
  # Enable ser2net for USB device forwarding to Home Assistant VM
  # Presents Zwave and Zigbee USB radios over network
  services.ser2net = {
    enable = true;
    configFile = pkgs.writeText "ser2net.yaml" ''
      %YAML 1.1
      ---
      connection: &zbt-2
        accepter: tcp,20111
        connector: serialdev,/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90BC05C-if00,460800n81,local
        options:
          kickolduser: true

      connection: &zwa-2
        accepter: tcp,20110
        connector: serialdev,/dev/serial/by-id/usb-Nabu_Casa_ZWA-2_80B54EE14C78-if00,115200n81,local
        options:
          kickolduser: true
    '';
  };
}

{ config, lib, pkgs, ... }:

with lib;

let
  # Define your USB device mappings here
  deviceMappings = [
    {
      name = "ttyXSWCORE1-A";
      type = "by-port";
      path = "1-8.1.3";
    }
    {
      name = "ttyXSWCORE1-B";
      type = "by-port";
      path = "1-8.1.4";
    }
    {
      name = "ttyXKVM";
      type = "by-port";
      path = "1-8.2";
    }
    {
      name = "ttyXSWLAB";
      type = "by-id";
      path = "usb-FTDI_FT232R_USB_UART_ABSCDWSQ-if00-port0";
    }
    {
      name = "ttyXUPS";
      type = "by-id";
      path = "usb-FTDI_FT232R_USB_UART_A9RTYGPF-if00-port0";
    }
  ];

  # Generate rules based on mapping type
  mkUdevRuleByType = mapping:
    if mapping.type == "by-id"
    then ''SYMLINK=="serial/by-id/${mapping.path}", SYMLINK+="${mapping.name}"''
    else ''SUBSYSTEM=="tty", KERNELS=="usb-*-${mapping.path}", SYMLINK+="${mapping.name}"'';

  # Generate udev rules for each device
  mkUdevRule = mapping: ''
    ${mkUdevRuleByType mapping}
  '';

in {
  config = {
    services.udev.extraRules = concatStrings (map mkUdevRule deviceMappings);
  };
}

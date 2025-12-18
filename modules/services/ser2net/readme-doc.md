# Ser2net Service Module

## Overview
This module provides a declarative way to configure ser2net, which presents USB serial devices on the network via TCP. This is particularly useful for exposing USB radios (Zwave, Zigbee, etc.) to remote systems like Home Assistant VMs.

## Features
- Simple single-device configuration
- Systemd service integration
- Security hardening built-in
- Automatic dialout group management

## Configuration Options
- `enable`: Enable the ser2net service
- `port`: TCP port to listen on (default: 2000)
- `device`: Serial device path (e.g., `/dev/ttyUSB0` or by-id path)
- `baudrate`: Serial baud rate (default: 115200)
- `user`: User to run as (default: "root")
- `group`: Group to run as (default: "dialout")
- `extraConfig`: Additional configuration lines

## Example Usage
```nix
services.ser2net = {
  enable = true;
  port = 8888;
  device = "/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_C1302F8F-if00-port0";
  baudrate = 115200;
};
```

## Notes
- Use `/dev/serial/by-id/` paths for stable device identification
- The service runs with minimal privileges but requires access to `/dev`
- Default user is root to ensure USB device access

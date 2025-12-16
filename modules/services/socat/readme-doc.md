# Socat Service Module

## Overview
This module provides a declarative way to configure and run socat relay instances as systemd services. Socat is a powerful utility for bidirectional data transfer between two independent data channels.

## Features
- Multiple named socat instances
- Systemd service management with automatic restart
- Configurable user/group permissions
- Support for all socat address types (TCP, UDP, Unix sockets, files, processes, etc.)

## Configuration Options

### `services.socat.enable`
- Type: `boolean`
- Default: `false`
- Enable the socat service module

### `services.socat.instances.<name>`
Each instance creates a systemd service named `socat-<name>`.

#### `source`
- Type: `string`
- The source address specification (socat first address)
- Examples:
  - `"TCP-LISTEN:8080,fork,reuseaddr"` - Listen on TCP port 8080
  - `"UDP-LISTEN:5353,reuseaddr"` - Listen on UDP port 5353
  - `"UNIX-LISTEN:/tmp/socket,fork"` - Listen on Unix socket

#### `destination`
- Type: `string`
- The destination address specification (socat second address)
- Examples:
  - `"TCP:remote-host:80"` - Connect to TCP host
  - `"EXEC:/usr/bin/program"` - Execute a program
  - `"FILE:/var/log/output.log"` - Write to a file

#### `options`
- Type: `list of strings`
- Default: `[]`
- Additional socat command-line options
- Common options:
  - `["-d" "-d"]` - Verbose logging (debug level)
  - `["-v"]` - Verbose mode
  - `["-T" "10"]` - Set timeout

#### `user`
- Type: `string`
- Default: `"nobody"`
- User to run the socat process as

#### `group`
- Type: `string`
- Default: `"nogroup"`
- Group to run the socat process as

## Usage Examples

### TCP Port Forwarding
```nix
services.socat = {
  enable = true;
  instances = {
    web-proxy = {
      source = "TCP-LISTEN:8080,fork,reuseaddr";
      destination = "TCP:backend-server:80";
      options = [ "-d" "-d" ];  # Verbose logging
    };
  };
};
```

### Audio Stream Relay
```nix
services.socat = {
  enable = true;
  instances = {
    audio-relay = {
      source = "TCP-LISTEN:8000,fork,reuseaddr";
      destination = "TCP:audio-source:8000";
      user = "mpd";
      group = "audio";
    };
  };
};
```

### UDP to TCP Converter
```nix
services.socat = {
  enable = true;
  instances = {
    udp-to-tcp = {
      source = "UDP-LISTEN:5353,reuseaddr";
      destination = "TCP:dns-server:53";
    };
  };
};
```

### Serial Port Forwarding
```nix
services.socat = {
  enable = true;
  instances = {
    serial-forward = {
      source = "TCP-LISTEN:2323,fork,reuseaddr";
      destination = "/dev/ttyUSB0,raw,echo=0";
      user = "dialout";
      group = "dialout";
    };
  };
};
```

## Systemd Service Management

Each instance creates a systemd service that can be managed with:
```bash
# Status of a specific instance
systemctl status socat-<name>

# Start/stop/restart
systemctl start socat-<name>
systemctl stop socat-<name>
systemctl restart socat-<name>

# View logs
journalctl -u socat-<name> -f
```

## Common Use Cases

1. **Port Forwarding**: Forward traffic from one port to another
2. **Protocol Conversion**: Convert between TCP/UDP or other protocols
3. **Serial Device Network Access**: Expose serial devices over network
4. **Audio Streaming**: Relay audio streams between services
5. **Logging/Debugging**: Intercept and log network traffic
6. **Unix Socket Bridging**: Connect Unix sockets to network sockets

## See Also
- [Socat Manual](http://www.dest-unreach.org/socat/doc/socat.html)
- [Socat Examples](http://www.dest-unreach.org/socat/doc/socat-openssltunnel.html)

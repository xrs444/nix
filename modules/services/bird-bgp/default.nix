# Summary: NixOS module for Bird2 BGP service, peering with Cilium (K8s CNI) on cluster hosts.
{
  hostname,
  lib,
  pkgs,
  ...
}:

let
  nodeConfigs = {
    xsvr1 = { routerId = "172.20.3.201"; };
    xsvr2 = { routerId = "172.20.3.202"; };
    xsvr3 = { routerId = "172.20.3.203"; };
    xsvr4 = { routerId = "172.20.3.204"; };
  };

  localASN = 65000;
  ciliumASN = 65001;
  vipAddress = "172.20.3.200";

  # Talos VM IPs — these are the Cilium BGP peers. Add new nodes here.
  talosNodes = [
    "172.20.3.10"
    "172.20.3.20"
    "172.20.3.30"
    "172.20.3.40"
  ];

  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;

  # Generate a passive BGP peer block for each Talos node
  mkPeerBlock = idx: ip: ''
    protocol bgp cilium_${toString idx} from cilium_template {
      neighbor ${ip} as ${toString ciliumASN};
    }
  '';

  peerBlocks = lib.concatStringsSep "\n" (lib.imap1 mkPeerBlock talosNodes);
in

if currentNode == null then
  { }
else
  {
    services.bird = {
      enable = true;
      config = ''
        log syslog all;
        router id ${currentNode.routerId};

        protocol device {
          scan time 10;
        }

        protocol kernel {
          ipv4 {
            export all;
            import none;
          };
        }

        protocol kernel {
          ipv6 {
            export all;
            import none;
          };
        }

        # Shared settings for all Cilium peers. Sessions stay on IPv4 transport
        # (local/neighbor addresses below are unchanged) — the ipv6 channel adds
        # multiprotocol BGP capability (RFC 4760/5549) to carry IPv6 NLRI over
        # that same session, rather than standing up a second v6-transport
        # session. This is deliberately scoped to "bird is ready," not "v6
        # routes actually flow yet" — Cilium's own BGP peer config still needs
        # its ipv6/unicast family added (flux side) and Cilium's IPv6 datapath
        # (enableIPv6) is still off, so there is no v6 CIDR for Cilium to
        # advertise yet regardless. See docs/ipv6-addressing.md Phase 7.
        template bgp cilium_template {
          local ${vipAddress} as ${toString localASN};
          passive;
          hold time 9;
          keepalive time 3;
          connect retry time 15;
          graceful restart;

          ipv4 {
            import all;
            export all;
          };
          ipv6 {
            import all;
            export all;
          };
        }

        ${peerBlocks}
      '';
    };

    # Bird exporter for Prometheus monitoring
    services.prometheus.exporters.bird = {
      enable = true;
      port = 9324;
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };

    # BGP health check script (matches pattern from xts1/xts2)
    environment.etc."check-bgp-session.sh" = {
      text = ''
        #!/bin/sh
        if ! systemctl is-active --quiet bird.service; then
          exit 1
        fi
        ${pkgs.bird2}/bin/birdc show protocols | grep -E 'BGP.*Established' > /dev/null
        exit $?
      '';
      mode = "0755";
    };

    # Ensure Bird starts after keepalived has assigned the VIP (172.20.3.200)
    systemd.services.bird.after = [ "keepalived.service" ];
    systemd.services.bird.wants = [ "keepalived.service" ];

    networking.firewall = {
      allowedTCPPorts = [ 179 ]; # BGP port
    };
  }

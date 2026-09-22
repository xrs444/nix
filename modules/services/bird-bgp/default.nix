# Summary: NixOS module for Bird BGP service, peering with Cilium (K8s CNI) on cluster hosts.
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
  vipAddressV6 = "fd66:150f:7361:16::200";

  # Talos VM IPs — these are the Cilium BGP peers. Add new nodes here.
  talosNodes = [
    "172.20.3.10"
    "172.20.3.20"
    "172.20.3.30"
    "172.20.3.40"
  ];

  # Talos VMs' own IPv6 addresses on VLAN 22 (bridge22), SLAAC/EUI-64-derived from each
  # VM's MAC — confirmed live 2026-09-21 via `kubectl get nodes -o json` status.addresses.
  # Not following the "::<last v4 octet>" static convention used elsewhere in
  # docs/ipv6-addressing.md because Talos assigns these itself; stable in practice
  # (tied to each VM's MAC) but will need updating here if a VM is ever recreated with a
  # new MAC. Order matches talosNodes (xsvr1..4).
  talosNodesV6 = [
    "fd66:150f:7361:16:5054:ff:fe8d:2eef" # xsvr1
    "fd66:150f:7361:16:5054:ff:fe8d:2efe" # xsvr2
    "fd66:150f:7361:16:5054:ff:fe8d:2eff" # xsvr3
    "fd66:150f:7361:16:5054:ff:fe8d:2efd" # xsvr4
  ];

  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;

  # Generate a passive BGP peer block for each Talos node
  mkPeerBlock = idx: ip: ''
    protocol bgp cilium_${toString idx} from cilium_template {
      neighbor ${ip} as ${toString ciliumASN};
    }
  '';

  mkPeerBlockV6 = idx: ip: ''
    protocol bgp cilium_v6_${toString idx} from cilium_template_v6 {
      neighbor ${ip} as ${toString ciliumASN};
    }
  '';

  peerBlocks = lib.concatStringsSep "\n" (lib.imap1 mkPeerBlock talosNodes);
  peerBlocksV6 = lib.concatStringsSep "\n" (lib.imap1 mkPeerBlockV6 talosNodesV6);
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

        # Shared settings for all Cilium peers, IPv4 transport, IPv4 AFI only.
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
        }

        ${peerBlocks}

        # Genuinely separate IPv6-transport session, not a multiprotocol add-on to the
        # v4 template above. Cilium's BGP control plane (GoBGP) derives a route's
        # next-hop from the peering session's own address family — over an IPv4-transport
        # session it maps an IPv4 next-hop for IPv6 NLRI too, which bird correctly rejects
        # ("Invalid NEXT_HOP attribute - mismatched address family"). Confirmed still true
        # on Cilium 1.20.2: cilium/cilium#37831 was closed as an accepted explanation of
        # GoBGP's next-hop design (no code fix ever landed, mechanism unchanged since),
        # and the reporter confirmed two separate peers — one v4-only, one v6-only — is
        # what actually works. See docs/ipv6-addressing.md Phase 6.
        template bgp cilium_template_v6 {
          local ${vipAddressV6} as ${toString localASN};
          passive;
          hold time 9;
          keepalive time 3;
          connect retry time 15;
          graceful restart;

          ipv6 {
            import all;
            export all;
          };
        }

        ${peerBlocksV6}
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
        ${pkgs.bird3}/bin/birdc show protocols | grep -E 'BGP.*Established' > /dev/null
        exit $?
      '';
      mode = "0755";
    };

    # Ensure Bird starts after keepalived has assigned the VIPs (172.20.3.200, fd66:150f:7361:16::200)
    systemd.services.bird.after = [ "keepalived.service" ];
    systemd.services.bird.wants = [ "keepalived.service" ];

    networking.firewall = {
      allowedTCPPorts = [ 179 ]; # BGP port
    };
  }

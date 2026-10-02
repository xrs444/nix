{ ... }:
{

  # Termix (k8s pod on 172.20.3.0/24) was tripping fail2ban's maxretry=3 sshd
  # jail while the routing issue to the main IP was being worked out.
  services.fail2ban.ignoreIP = [ "172.20.3.0/24" ];

  # Same Termix source as above: its host-status poll opens and closes a TCP
  # connection to :22 every ~65s without authenticating (confirmed via
  # journalctl -u sshd — connects from 172.20.3.10, the Talos node the Termix
  # pod is scheduled on, since pod egress SNATs to the node IP). OpenSSH >=9.8's
  # PerSourcePenalties logs this as a deferred 1s srclimit penalty every cycle
  # (never enforced — below the 15s `min` — but floods the sshd journal).
  # bug-1023 (2026-09-24): investigated as a possible cause of CI deploy
  # failures; it wasn't (that was a corrupted nix.custom.conf, unrelated) but
  # the noise is real, so exempt the k8s node bridge from the penalty.
  services.openssh.settings.PerSourcePenaltyExemptList = "172.20.3.0/24";

  # Shared VM boot media (Talos factory ISO, etc.) — see nix/hosts/nixos/xsvr1/shares.nix.
  fileSystems."/mnt/xsvr1/distribute/iso" = {
    device = "xsvr1.lan:/zfs/distribute/iso";
    fsType = "nfs";
    options = [
      "nfsvers=4.2" "ro" "soft" "timeo=30"
      "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "nofail"
    ];
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "5-bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer2+3";
          MIIMonitorSec = "0.100s";
          LACPTransmitRate = "fast";
        };
      };
      "10-bond0.21" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.21";
        };
        vlanConfig.Id = 21;
      };
      "21-bond0.22" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.22";
        };
        vlanConfig.Id = 22;
      };
      "22-bond0.10" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.10";
        };
        vlanConfig.Id = 10;
      };
      "25-bridge21" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge21";
        };
        bridgeConfig = {
          ForwardDelaySec = 0;
          HelloTimeSec = 2;
          AgeingTimeSec = 300;
          STP = false;
        };
      };
      "40-bridge22" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge22";
        };
        bridgeConfig = {
          ForwardDelaySec = 0;
          HelloTimeSec = 2;
          AgeingTimeSec = 300;
          STP = false;
        };
      };
    };
    networks = {
      "30-enp2s0f0" = {
        matchConfig.Name = "enp2s0f0";
        networkConfig.Bond = "bond0";
      };
      "30-enp2s0f1" = {
        matchConfig.Name = "enp2s0f1";
        networkConfig.Bond = "bond0";
      };
      "50-bond0" = {
        matchConfig.Name = "bond0";
        # fd66:150f:7361:0014::/64 is VLAN 20's ULA subnet (server-core, see
        # docs/ipv6-addressing.md) — this is the untagged native VLAN on bond0.
        address = [
          "172.20.1.20/24"
          "fd66:150f:7361:0014::20/64"
        ];
        gateway = [ "172.20.1.250" ];
        dns = [ "172.20.1.250" ];
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = true;
          # iprouting sets all.forwarding=1 which propagates to bond0.forwarding=1,
          # causing the kernel to silently set accept_ra=0 on bond0. Setting
          # IPv6Forwarding=false here scopes forwarding off for this uplink interface
          # so the kernel permits RA acceptance and SLAAC from the Firewalla.
          IPv6Forwarding = false;
        };
        # This VLAN is ULA-only (fd66:150f:7361:0014::/64, see docs/ipv6-addressing.md) —
        # there is no real internet-routable IPv6 behind it. UseGateway=false keeps
        # on-link prefix learning from RA (harmless) but stops bond0 from installing a
        # default route it can't actually deliver on. bond0.10 (below) is the sole
        # interface meant to carry the IPv6 default route — see bug-1063/1066.
        ipv6AcceptRAConfig = {
          UseGateway = false;
        };
        vlan = [
          "bond0.21"
          "bond0.22"
          "bond0.10"
        ];
      };
      "55-bond0.21" = {
        matchConfig.Name = "bond0.21";
        networkConfig = {
          Bridge = "bridge21";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "57-bond0.22" = {
        matchConfig.Name = "bond0.22";
        networkConfig = {
          Bridge = "bridge22";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
          Promiscuous = true;
        };
      };
      "68-bond0.10" = {
        matchConfig.Name = "bond0.10";
        # VLAN 10 (172.18.10.0/24) is GUA-role on the Firewalla (stateless DHCPv6,
        # see docs/ipv6-addressing.md) — IPv6-only here, deliberately no address/DHCP
        # for v4: v4 egress already works fine via bond0's static gateway. This is the
        # one interface meant to carry the real internet-routable IPv6 default route
        # for an otherwise ULA-only host (bug-1063/1066).
        networkConfig = {
          IPv6AcceptRA = true;
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "70-bridge21" = {
        matchConfig.Name = "bridge21";
        bridgeConfig = { };
        networkConfig = {
          IPMasquerade = "no";
        };
        # ULA-role VLAN (fd66:150f:7361:0015::/64) — same dead-end-default-route issue
        # bond0 had (bug-1063/1066): RA still advertises a route here even though
        # there's no real internet IPv6 behind it. bond0.10 is the only interface that
        # should carry the IPv6 default route.
        ipv6AcceptRAConfig = {
          UseGateway = false;
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "90-bridge22" = {
        matchConfig.Name = "bridge22";
        # fd66:150f:7361:0016::/64 is VLAN 22's ULA subnet (see docs/ipv6-addressing.md) —
        # k8s/BGP infra gets a stable address here since VLAN 22 is ULA-role, not GUA.
        address = [
          "172.20.3.202/24"
          "fd66:150f:7361:0016::202/64"
        ];
        bridgeConfig = { };
        networkConfig = {
          IPMasquerade = "no";
        };
        # Same dead-end-default-route issue as bond0/bridge21 above (bug-1063/1066) —
        # UseGateway=false keeps the static ULA address and on-link behavior (BGP/VRRP
        # still work, both same-VLAN) without claiming this is a route to the internet.
        ipv6AcceptRAConfig = {
          UseGateway = false;
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
    };
  };
}

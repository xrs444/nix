{ pkgs, lib, ... }:
{

  networking = {
    useNetworkd = true;
  };
  systemd.network = {
    enable = true;
    netdevs = {
      # VLANs on enp1s0f0
      "10-enp1s0f0.21" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "enp1s0f0.21";
        };
        vlanConfig.Id = 21;
      };
      "15-enp1s0f0.16" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "enp1s0f0.16";
        };
        vlanConfig.Id = 16;
      };
      "20-enp1s0f0.17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "enp1s0f0.17";
        };
        vlanConfig.Id = 17;
      };
      # Bridges
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
      "30-bridge16" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge16";
        };
        bridgeConfig = {
          ForwardDelaySec = 0;
          HelloTimeSec = 2;
          AgeingTimeSec = 300;
          STP = false;
        };
      };
      "35-bridge17" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge17";
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
      # Parent interface for VLANs
      "00-enp1s0f0" = {
        matchConfig.Name = "enp3s0f0";
        networkConfig = {
          LinkLocalAddressing = "no";
          DHCP = "yes";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      # Attach VLANs to physical NIC
      "10-enp1s0f0.21" = {
        matchConfig.Name = "enp1s0f0.21";
        networkConfig = {
          Bridge = "bridge21";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "15-enp1s0f0.16" = {
        matchConfig.Name = "enp1s0f0.16";
        networkConfig = {
          Bridge = "bridge16";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "20-enp1s0f0.17" = {
        matchConfig.Name = "enp1s0f0.17";
        networkConfig = {
          Bridge = "bridge17";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "70-bridge21" = {
        matchConfig.Name = "bridge21";
        bridgeConfig = {};
        networkConfig = {
          LinkLocalAddressing = "no";
          IPMasquerade = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "75-bridge16" = {
        matchConfig.Name = "bridge16";
        bridgeConfig = {};
        networkConfig = {
          LinkLocalAddressing = "no";
          IPMasquerade = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "80-bridge17" = {
        matchConfig.Name = "bridge17";
        bridgeConfig = {};
        networkConfig = {
          LinkLocalAddressing = "no";
          IPMasquerade = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
    };
  };
}

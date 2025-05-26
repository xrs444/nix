{ pkgs, lib, ... }:
{

  networking = {
    hostId = "8f9996ca";
    useNetworkd = true;
    interfaces."bond0.22".proxyARP = true;
    interfaces."bridge22".proxyARP = true;
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
      "15-bond0.16" = {
        netdevConfig = {
          Kind = "vlan";
         Name = "bond0.16";
         };
         vlanConfig.Id = 16;
      };
     "20-bond0.17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.17";
         };
         vlanConfig.Id = 17;
      };
     "21-bond0.22" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond0.22";
         };
         vlanConfig.Id = 22;
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
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        vlan = [
          "bond0.21"
          "bond0.16"
          "bond0.17"
          "bond0.22"
        ];
      };
      "55-bond0.21" = {
        matchConfig.Name = "bond0.21";
        networkConfig = {
        Bridge = "bridge21";
        LinkLocalAddressing = "no";
      };
        linkConfig = {
          RequiredForOnline = "carrier";
       };
      };
      "57-bond0.22" = {
        matchConfig.Name = "bond0.22";
        networkConfig = {
          Bridge = "bridge22";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
          Promiscuous= true;
        };
      };
      "60-bond0.17" = {
        matchConfig.Name = "bond0.17";
        networkConfig = {
          Bridge = "bridge17";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
       };
      };
     "65-bond0.16" = {
        matchConfig.Name = "bond0.16";
       networkConfig ={ 
          Bridge = "bridge16";
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

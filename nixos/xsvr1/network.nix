{ pkgs, lib, ... }:
{

  networking.hostId = "0814bb9a";
  networking.useNetworkd = true;

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
#      "10-bond0.21" = {
#        netdevConfig = {
#          Kind = "vlan";
#          Name = "bond0.21";
#         };
#        vlanConfig.Id = 21;
#      };
#      "15-bond0.16" = {
#        netdevConfig = {
#          Kind = "vlan";
#         Name = "bond0.16";
#         };
#         vlanConfig.Id = 16;
#      };
#     "20-bond0.17" = {
#        netdevConfig = {
#          Kind = "vlan";
#          Name = "bond0.17";
#         };
#         vlanConfig.Id = 17;
#      };
#      "25-bridge21" = {
#        netdevConfig = {
#          Kind = "bridge";
#          Name = "bridge21";
#        };
#        bridgeConfig = {
#          ForwardDelaySec = 0;
#          HelloTimeSec = 2;
#          AgeingTimeSec = 300;
#          STP = false;
#        };
#      };
#      "30-bridge16" = {
#        netdevConfig = {
#          Kind = "bridge";
#          Name = "bridge16";
#        };
#        bridgeConfig = {
#          ForwardDelaySec = 0;
#          HelloTimeSec = 2;
#          AgeingTimeSec = 300;
#          STP = false;
#        };
#      };
#      "35-bridge17" = {
#        netdevConfig = {
#          Kind = "bridge";
#          Name = "bridge17";
#        };
#        bridgeConfig = {
#          ForwardDelaySec = 0;
#          HelloTimeSec = 2;
#          AgeingTimeSec = 300;
#          STP = false;
#        };
#      };
      
# VM Temporary testing for K3S network block issue.

      "5-bond1" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond1";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer2+3";
          MIIMonitorSec = "0.100s";
          LACPTransmitRate = "fast";
        };
      };
      "10-bond1.21" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond1.21";
         };
        vlanConfig.Id = 21;
      };
      "15-bond1.16" = {
        netdevConfig = {
          Kind = "vlan";
         Name = "bond1.16";
         };
         vlanConfig.Id = 16;
      };
     "20-bond1.17" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "bond1.17";
         };
         vlanConfig.Id = 17;
      };
      "25-vmbridge21" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "vmbridge21";
        };
        bridgeConfig = {
          ForwardDelaySec = 0;
          HelloTimeSec = 2;
          AgeingTimeSec = 300;
          STP = false;
        };
      };
      "30-vmbridge16" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "vmbridge16";
        };
        bridgeConfig = {
          ForwardDelaySec = 0;
          HelloTimeSec = 2;
          AgeingTimeSec = 300;
          STP = false;
        };
      };
      "35-vmbridge17" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "vmbridge17";
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
      "40-enp3s0f0" = {
        matchConfig.Name = "enp3s0f0";
        networkConfig.Bond = "bond0";
#        linkConfig.RequiredForOnline = "enslaved";
      };
      "40-enp3s0f1" = {
        matchConfig.Name = "enp3s0f1";
        networkConfig.Bond = "bond0";
#        linkConfig.RequiredForOnline = "enslaved";
      };
      "50-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
#        vlan = [
#          "bond0.21"
#          "bond0.16"
#          "bond0.17"
#        ];
      };
#      "55-bond0.21" = {
#        matchConfig.Name = "bond0.21";
#        networkConfig = {
#        Bridge = "bridge21";
#        LinkLocalAddressing = "no";
#      };
#        linkConfig = {
#          RequiredForOnline = "carrier";
#       };
#      };
#      "60-bond0.17" = {
#        matchConfig.Name = "bond0.17";
#        networkConfig = {
#          Bridge = "bridge17";
#          LinkLocalAddressing = "no";
#        };
#        linkConfig = {
#          RequiredForOnline = "carrier";
#       };
#      };
#
#     "65-bond0.16" = {
#        matchConfig.Name = "bond0.16";
#       networkConfig ={ 
#          Bridge = "bridge16";
#          LinkLocalAddressing = "no";
#        };
#        linkConfig = {
#          RequiredForOnline = "carrier";
#        };
#      };
#     "70-bridge21" = {
#        matchConfig.Name = "bridge21";
#        bridgeConfig = {};
#        networkConfig = {
#          LinkLocalAddressing = "no";
#          IPMasquerade = "no";
#        };
#        linkConfig = {
#          RequiredForOnline = "carrier";
#        };
#      };
#      "75-bridge16" = {
#        matchConfig.Name = "bridge16";
#        bridgeConfig = {};
#        networkConfig = {
#          LinkLocalAddressing = "no";
#          IPMasquerade = "no";
#        };
#        linkConfig = {
#          RequiredForOnline = "carrier";
#        };
#      };
#      "80-bridge17" = {
#        matchConfig.Name = "bridge17";
#        bridgeConfig = {};
#        networkConfig = {
#          LinkLocalAddressing = "no";
#          IPMasquerade = "no";
#        };
#        linkConfig = {
#          RequiredForOnline = "carrier";
#        };
#      };

# Temporary config for VM K3S issue

      "40-en01" = {
        matchConfig.Name = "eno1";
        networkConfig.Bond = "bond1";
#        linkConfig.RequiredForOnline = "enslaved";
      };
      "40-eno2" = {
        matchConfig.Name = "eno2";
        networkConfig.Bond = "bond1";
#        linkConfig.RequiredForOnline = "enslaved";
      };
      "50-bond1" = {
        matchConfig.Name = "bond1";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        vlan = [
          "bond1.21"
          "bond1.16"
          "bond1.17"
        ];
      };
      "55-bond1.21" = {
        matchConfig.Name = "bond1.21";
        networkConfig = {
          Bridge = "vmbridge21";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
       };
      };
      "60-bond1.17" = {
        matchConfig.Name = "bond1.17";
        networkConfig = {
          Bridge = "vmbridge17";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
       };
      };

     "65-bond1.16" = {
        matchConfig.Name = "bond1.16";
       networkConfig ={ 
          Bridge = "vmbridge16";
          LinkLocalAddressing = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "70-vmbridge21" = {
        matchConfig.Name = "vmbridge21";
        bridgeConfig = {};
        networkConfig = {
          LinkLocalAddressing = "no";
          IPMasquerade = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "75-vmbridge16" = {
        matchConfig.Name = "vmbridge16";
        bridgeConfig = {};
        networkConfig = {
          LinkLocalAddressing = "no";
          IPMasquerade = "no";
        };
        linkConfig = {
          RequiredForOnline = "carrier";
        };
      };
      "80-vmbridge17" = {
        matchConfig.Name = "vmbridge17";
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

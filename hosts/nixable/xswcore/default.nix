# Nixible configuration for xswcore (Brocade ICX-7250 2-unit stack)
# Manages core switching: LAGs, VLANs, interfaces, routing, and services
# Requires: community.network collection (icx_* modules)
# Auth: password-based (key-auth disabled on switch); secrets via ansible-vault
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};
in {
  # community.network collection required for ICX switch management
  # Update version/hash after: ansible-galaxy collection download community.network
  collections = common.collections // {
    "community-network" = {
      version = "5.0.3";
      hash = "sha256-REPLACE_WITH_ACTUAL_HASH";
    };
  };

  # Inventory: ICX switch uses network_cli, not SSH like Bazzite hosts
  inventory = {
    all = {
      hosts = {
        xswcore = {
          ansible_host = "172.18.4.100";
          ansible_connection = "network_cli";
          ansible_network_os = "community.network.icx";
          ansible_user = "ansible-local";
          ansible_password = "{{ vault_ansible_password }}";
          ansible_become = true;
          ansible_become_method = "enable";
          ansible_become_password = "{{ vault_enable_password }}";
        };
      };
    };
  };

  playbook = [
    {
      name = "Configure xswcore ICX-7250 Stack";
      hosts = "xswcore";
      gather_facts = false;
      # Secrets injected at runtime via sops: nix/secrets/xswcore.yaml
      # See justfile configure-xswcore recipe for decryption flow

      tasks = [

        # =========================================================
        # SYSTEM
        # =========================================================

        {
          name = "Set hostname";
          "community.network.icx_system" = {
            hostname = "xswcore";
          };
        }

        {
          name = "Configure global settings";
          "community.network.icx_config" = {
            lines = [
              "default-vlan-id 4000"
              "global-stp"
              "ip dhcp-client disable"
              "no telnet server"
              "no web-management http"
              "hitless-failover enable"
              "cdp run"
              "optical-monitor"
              "optical-monitor non-ruckus-optic-enable"
              "enable aaa console"
              "clock timezone us Arizona"
              "lldp tagged-packets process"
              "ip ssh key-authentication no"
              "ip ssh encryption disable-aes-cbc"
              "manager disable"
              "manager port-list 987"
            ];
          };
        }

        {
          name = "Configure AAA authentication";
          "community.network.icx_config" = {
            lines = [
              "aaa authentication web-server default local"
              "aaa authentication login default local"
            ];
          };
        }

        {
          name = "Configure SNMP";
          "community.network.icx_config" = {
            lines = [
              "snmp-server community {{ vault_snmp_community }} ro"
              "snmp-server contact xrs444@xrs444.net"
            ];
          };
        }

        {
          name = "Configure NTP";
          "community.network.icx_config" = {
            lines = [
              "disable serve"
              "server time.xrs444.net"
            ];
            parents = "ntp";
          };
        }

        {
          name = "Set enable password";
          "community.network.icx_config" = {
            lines = [ "enable super-user-password {{ vault_enable_password }}" ];
          };
          no_log = true;
        }

        # =========================================================
        # USER MANAGEMENT
        # =========================================================

        {
          name = "Configure local users";
          "community.network.icx_user" = {
            name = "{{ item.name }}";
            configured_password = "{{ item.password }}";
            state = "present";
          };
          no_log = true;
          loop = [
            { name = "super";         password = "{{ vault_user_super_password }}"; }
            { name = "ansible-local"; password = "{{ vault_ansible_password }}"; }
            { name = "thomas-local";  password = "{{ vault_user_thomas_password }}"; }
            { name = "dog";           password = "{{ vault_user_dog_password }}"; }
          ];
        }

        # =========================================================
        # LINK AGGREGATION
        # =========================================================

        {
          name = "Configure LAG xsvr1 (id 1) - LACP to xsvr1 SFP+";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/2/1 ethe 2/2/1"
              "force-up ethernet 1/2/1"
              "port-name xsvr-a ethernet 1/2/1"
              "port-name xsvr-b ethernet 2/2/1"
            ];
            parents = "lag xsvr1 dynamic id 1";
          };
        }

        {
          name = "Configure LAG xsvr2 (id 2) - LACP to xsvr2 SFP+";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/2/2 ethe 2/2/2"
              "force-up ethernet 1/2/2"
              "port-name xsvr2-b ethernet 1/2/2"
              "port-name xsvr2-b ethernet 2/2/2"
            ];
            parents = "lag xsvr2 dynamic id 2";
          };
        }

        {
          name = "Configure LAG xsvr3 (id 3) - LACP to xsvr3 SFP+";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/2/3 ethe 2/2/3"
              "force-up ethernet 1/2/3"
              "port-name xsvr3-b ethernet 1/2/3"
              "port-name xsvr3-b ethernet 2/2/3"
            ];
            parents = "lag xsvr3 dynamic id 3";
          };
        }

        {
          name = "Configure LAG xsvr-temp (id 4) - temporary server SFP+";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/2/4 ethe 2/2/4"
              "force-up ethernet 1/2/4"
            ];
            parents = "lag xsvr-temp dynamic id 4";
          };
        }

        {
          name = "Configure LAG rfcab (id 6) - RF cabinet uplink SFP+";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/2/5 ethe 2/2/5"
              "port-name rfcab-uplink-a ethernet 1/2/5"
              "port-name rfcab-uplink-b ethernet 2/2/5"
            ];
            parents = "lag rfcab dynamic id 6";
          };
        }

        {
          name = "Configure LAG xfw (id 10) - firewall SFP+";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/2/6 ethe 2/2/6"
              "port-name xfw-a ethernet 1/2/6"
              "port-name xfw-b ethernet 2/2/6"
            ];
            parents = "lag xfw dynamic id 10";
          };
        }

        {
          name = "Configure LAG xswoffice (id 11) - office switch uplink";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/1/47 ethe 2/1/47"
              "port-name xswoffice-a ethernet 1/1/47"
              "port-name xswoffice-b ethernet 2/1/47"
            ];
            parents = "lag xswoffice dynamic id 11";
          };
        }

        {
          name = "Configure LAG RFCab-Temp (id 12) - temporary RF cab uplink";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout long"
              "ports ethe 1/1/48 ethe 2/1/48"
              "port-name RFCab-Temp-a ethernet 1/1/48"
              "port-name RFCab-Temp-b ethernet 2/1/48"
            ];
            parents = "lag RFCab-Temp dynamic id 12";
          };
        }

        {
          name = "Configure LAG xswlab (id 13) - lab switch (static, no LACP)";
          "community.network.icx_config" = {
            lines = [
              "ports ethe 1/1/46 ethe 2/1/46"
              "force-up ethernet 1/1/46"
              "port-name xswlab-a ethernet 1/1/46"
              "port-name xswlab-b ethernet 2/1/46"
            ];
            parents = "lag xswlab dynamic id 13";
          };
        }

        {
          name = "Configure LAG xsvr1-vm (id 14) - xsvr1 VM traffic";
          "community.network.icx_config" = {
            lines = [
              "lacp-timeout short"
              "ports ethe 1/1/7 ethe 2/1/7"
              "force-up ethernet 1/1/7"
              "port-name xsvr1-vm-a ethernet 1/1/7"
              "port-name xsvr1-vm-b ethernet 2/1/7"
            ];
            parents = "lag xsvr1-vm dynamic id 14";
          };
        }

        # =========================================================
        # VLANs
        # =========================================================

        {
          name = "Configure VLAN 10 (FW - firewall transit)";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 10"
              "untagged ethe 1/1/37 ethe 1/1/45 ethe 2/1/45"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 10 name FW by port";
          };
        }

        {
          name = "Create VLAN 11 (unconfigured placeholder)";
          "community.network.icx_config" = {
            lines = [ "vlan 11 by port" ];
          };
        }

        {
          name = "Configure VLAN 14 (management)";
          "community.network.icx_config" = {
            lines = [
              "tagged ethe 1/1/44 lag 6 lag 10 lag 11 lag 12"
              "untagged ethe 1/1/2 ethe 1/1/4 ethe 1/1/13 ethe 1/1/14 ethe 2/1/1 ethe 2/1/2 ethe 2/1/13"
              "router-interface ve 14"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 14 name management by port";
          };
        }

        {
          name = "Configure VLAN 15 (Printers)";
          "community.network.icx_config" = {
            lines = [
              "tagged ethe 1/1/44 lag 10 lag 11"
              "spanning-tree"
            ];
            parents = "vlan 15 name Printers by port";
          };
        }

        {
          name = "Configure VLAN 16 (telephony)";
          "community.network.icx_config" = {
            lines = [
              "tagged ethe 1/1/44 lag 1 lag 2 lag 3 lag 4 lag 10 lag 11 lag 14"
              "untagged ethe 1/1/35 ethe 1/1/40"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 16 name telephony by port";
          };
        }

        {
          name = "Configure VLAN 17 (HomeAutomation)";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 1 lag 2 lag 3 lag 4 lag 6 lag 10 lag 12 lag 14"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 17 name HomeAutomation by port";
          };
        }

        {
          name = "Configure VLAN 18";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 10"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 18 by port";
          };
        }

        {
          name = "Configure VLAN 19 (provisioning)";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 10"
              "untagged ethe 1/1/44 lag 6 lag 11 lag 12"
              "spanning-tree"
            ];
            parents = "vlan 19 name provisioning by port";
          };
        }

        {
          name = "Configure VLAN 20";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 10"
              "untagged lag 1 lag 2 lag 3 lag 4"
            ];
            parents = "vlan 20 by port";
          };
        }

        {
          name = "Configure VLAN 21 (HomeVMs)";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 1 lag 2 lag 3 lag 4 lag 10 lag 14"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 21 name HomeVMs by port";
          };
        }

        {
          name = "Configure VLAN 22 (k8s)";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 1 lag 2 lag 3 lag 10"
              "untagged ethe 2/1/36"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 22 name k8s by port";
          };
        }

        {
          name = "Configure VLAN 100 (WiredClients)";
          "community.network.icx_config" = {
            lines = [
              "tagged ethe 1/1/44 lag 10 lag 11"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 100 name WiredClients by port";
          };
        }

        {
          name = "Configure WiFi VLANs (111-115) - all tagged to rfcab, xfw, RFCab-Temp";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 6 lag 10 lag 12"
              "spanning-tree 802-1w"
            ];
            parents = "vlan {{ item.id }} name {{ item.name }} by port";
          };
          loop = [
            { id = 111; name = "notthewifiyouarelookingfor"; }
            { id = 112; name = "WanIPlayWithMadness"; }
            { id = 113; name = "WiFiToTheDangerZone"; }
            { id = 114; name = "TotalEclipseOfTheUART"; }
            { id = 115; name = "HelloIsItWiFiYoureLookingFor"; }
          ];
        }

        {
          name = "Configure VLAN 1000 (Atlas)";
          "community.network.icx_config" = {
            lines = [
              "tagged ethe 1/1/11 ethe 2/1/44 lag 10"
              "untagged ethe 1/1/1"
              "spanning-tree 802-1w"
            ];
            parents = "vlan 1000 name Atlas by port";
          };
        }

        {
          name = "Configure VLAN 2000 (xswlab untagged trunk)";
          "community.network.icx_config" = {
            lines = [
              "tagged lag 10"
              "untagged lag 13"
            ];
            parents = "vlan 2000 by port";
          };
        }

        {
          name = "Configure VLANs 2001/2002/2004 (lab VLANs via xswlab)";
          "community.network.icx_config" = {
            lines = [ "tagged ethe 1/1/24 lag 10 lag 13" ];
            parents = "vlan {{ item }} by port";
          };
          loop = [ "2001" "2002" "2004" ];
        }

        {
          name = "Configure VLAN 4000 (DEFAULT-VLAN)";
          "community.network.icx_config" = {
            lines = [ "spanning-tree" ];
            parents = "vlan 4000 name DEFAULT-VLAN by port";
          };
        }

        # =========================================================
        # INTERFACES
        # =========================================================

        {
          name = "Configure interface port-names";
          "community.network.icx_config" = {
            lines = [ "port-name {{ item.name }}" ];
            parents = "interface ethernet {{ item.intf }}";
          };
          loop = [
            { intf = "1/1/1";  name = "atlas"; }
            { intf = "1/1/2";  name = "KVM"; }
            { intf = "1/1/4";  name = "xswlab"; }
            { intf = "1/1/13"; name = "xsvr1-mgmt"; }
            { intf = "1/1/14"; name = "xsvr3-mgmt"; }
            { intf = "1/1/25"; name = "xsvr1_impi"; }
            { intf = "1/1/26"; name = "xsvr2_impi"; }
            { intf = "1/1/27"; name = "xsvr3_ipmi"; }
            { intf = "1/1/43"; name = "xfw-temp-a"; }
            { intf = "1/1/44"; name = "UplinkToOfficeSwitch"; }
            { intf = "2/1/1";  name = "RackUPS"; }
            { intf = "2/1/2";  name = "JetKVM"; }
            { intf = "2/1/13"; name = "xsvr2-mgmt"; }
          ];
        }

        {
          name = "Disable unused/reserved interfaces";
          "community.network.icx_config" = {
            lines = [ "disable" ];
            parents = "interface ethernet {{ item }}";
          };
          loop = [ "1/1/8" "1/1/9" "1/1/43" "2/1/8" "2/1/9" ];
        }

        {
          name = "Configure legacy PoE interfaces (pre-802.3af devices)";
          "community.network.icx_config" = {
            lines = [ "legacy-inline-power" ];
            parents = "interface ethernet {{ item }}";
          };
          loop = [ "1/1/35" "1/1/45" ];
        }

        {
          name = "Disable inline power on xswlab LAG members (1/1/46, 2/1/46)";
          "community.network.icx_config" = {
            lines = [ "no inline power ethernet 1/1/46 ethernet 2/1/46" ];
          };
        }

        # =========================================================
        # LAYER 3
        # =========================================================

        {
          name = "Configure management VE 14 IP address";
          "community.network.icx_config" = {
            lines = [ "ip address 172.18.4.100 255.255.255.0" ];
            parents = "interface ve 14";
          };
        }

        {
          name = "Configure default route via xfw";
          "community.network.icx_static_route" = {
            prefix = "0.0.0.0";
            mask = "0.0.0.0";
            next_hop = "172.18.4.250";
            state = "present";
          };
        }

        # =========================================================
        # SAVE
        # =========================================================

        {
          name = "Save running configuration to startup-config";
          "community.network.icx_config" = {
            save_when = "changed";
          };
        }

      ]; # end tasks
    }
  ]; # end playbook
}

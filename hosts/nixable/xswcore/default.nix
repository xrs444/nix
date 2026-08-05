# Nixible configuration for xswcore (Brocade ICX-7250 2-unit stack)
# Manages core switching: LAGs, VLANs, interfaces, routing, and services
# Uses ansible.netcommon.cli_config + local terminal plugin (plugins/terminal/icx.py)
# Auth: ECDSA P-256 key-based for ansible-brocade; enable password for privilege escalation
# Secrets: nix/secrets/ansible-network.yaml (sops/age encrypted)
{...}: let
  common = import ../common/default.nix {};
in {
  collections = common.collections // {
    "ansible-netcommon" = {
      version = "5.0.0";
      hash = "sha256-REPLACE_WITH_ACTUAL_HASH";
    };
  };

  # Inventory: ICX switch uses network_cli with local icx terminal plugin
  # ansible_private_key_file path injected at runtime by the justfile recipe
  inventory = {
    all = {
      hosts = {
        xswcore = {
          ansible_host = "172.18.4.100";
          ansible_connection = "network_cli";
          ansible_network_os = "icx";
          ansible_user = "ansible-brocade";
          ansible_private_key_file = "{{ ansible_private_key_file }}";
          ansible_become = true;
          ansible_become_method = "enable";
          ansible_become_password = "{{ ansible_become_password }}";
        };
      };
    };
  };

  playbook = [
    {
      name = "Configure xswcore ICX-7250 Stack";
      hosts = "xswcore";
      gather_facts = false;

      tasks = [

        # =========================================================
        # SYSTEM
        # =========================================================

        {
          name = "Set hostname";
          "ansible.netcommon.cli_config" = {
            config = "hostname xswcore";
          };
        }

        {
          name = "Configure global settings";
          "ansible.netcommon.cli_config" = {
            config = ''
              default-vlan-id 4000
              global-stp
              ip dhcp-client disable
              no telnet server
              no web-management http
              hitless-failover enable
              cdp run
              optical-monitor
              optical-monitor down-port-enable
              optical-monitor non-ruckus-optic-enable
              clock timezone us Arizona
              lldp tagged-packets process
              ip ssh scp disable
              ip ssh encryption disable-aes-cbc
              manager disable
              manager port-list 987
            '';
          };
        }

        {
          name = "Configure ansible-brocade SSH authorized key";
          # ECDSA P-256 key — FastIron 09.x supports ecdsa-sha2-nistp256 in pub-key-chain
          # ansible_public_key injected from ansible-network.yaml
          "ansible.netcommon.cli_config" = {
            config = ''
              ip ssh pub-key-chain
               user-key ansible-brocade
                key-string {{ ansible_public_key }}
            '';
          };
        }

        {
          name = "Configure AAA authentication";
          "ansible.netcommon.cli_config" = {
            config = ''
              aaa authentication web-server default local
              aaa authentication login default local
            '';
          };
        }

        {
          name = "Configure SNMP";
          "ansible.netcommon.cli_config" = {
            config = ''
              snmp-server community {{ vault_snmp_community }} ro
              snmp-server contact xrs444@xrs444.net
            '';
          };
        }

        {
          name = "Configure NTP";
          "ansible.netcommon.cli_config" = {
            config = ''
              ntp
               disable serve
               server time.xrs444.net
            '';
          };
        }

        # =========================================================
        # USER MANAGEMENT
        # =========================================================

        {
          name = "Configure local users";
          "ansible.netcommon.cli_config" = {
            config = "username {{ item.name }} privilege 0 password {{ item.password }}";
          };
          no_log = true;
          loop = [
            { name = "super";           password = "{{ vault_user_super_password }}"; }
            { name = "ansible-brocade"; password = "{{ vault_user_ansible_password }}"; }
            { name = "thomas-local";    password = "{{ vault_user_thomas_password }}"; }
            { name = "dog";             password = "{{ vault_user_dog_password }}"; }
          ];
        }

        # =========================================================
        # LINK AGGREGATION
        # =========================================================

        {
          name = "Configure LAG xsvr1 (id 1) - LACP to xsvr1 SFP+";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xsvr1 dynamic id 1
               lacp-timeout short
               ports ethe 1/2/1 ethe 2/2/1
               force-up ethernet 1/2/1
               port-name xsvr-a ethernet 1/2/1
               port-name xsvr-b ethernet 2/2/1
            '';
          };
        }

        {
          name = "Configure LAG xsvr2 (id 2) - LACP to xsvr2 SFP+";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xsvr2 dynamic id 2
               lacp-timeout short
               ports ethe 1/2/2 ethe 2/2/2
               force-up ethernet 1/2/2
               port-name xsvr2-b ethernet 1/2/2
               port-name xsvr2-b ethernet 2/2/2
            '';
          };
        }

        {
          name = "Configure LAG xsvr3 (id 3) - LACP to xsvr3 SFP+";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xsvr3 dynamic id 3
               lacp-timeout short
               ports ethe 1/2/3 ethe 2/2/3
               force-up ethernet 1/2/3
               port-name xsvr3-b ethernet 1/2/3
               port-name xsvr3-b ethernet 2/2/3
            '';
          };
        }

        {
          name = "Configure LAG rfcab (id 6) - RF cabinet uplink SFP+";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag rfcab dynamic id 6
               lacp-timeout short
               ports ethe 1/2/5 ethe 2/2/5
               port-name rfcab-uplink-a ethernet 1/2/5
               port-name rfcab-uplink-b ethernet 2/2/5
            '';
          };
        }

        {
          name = "Configure LAG xfw (id 10) - firewall SFP+";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xfw dynamic id 10
               lacp-timeout short
               ports ethe 1/2/6 ethe 2/2/6
               port-name xfw-a ethernet 1/2/6
               port-name xfw-b ethernet 2/2/6
            '';
          };
        }

        {
          # Replaces the old git-declared "lag11-xswoffice" (id 11, ports 1/1/47+2/1/47),
          # which was disconnected/superseded live and never actually carried traffic.
          # This is the REAL office uplink — discovered live on 2026-08-04 (bug/drift not
          # previously reflected in git): id 15, ports 1/2/4+2/2/4, name "xswoffce" (sic,
          # matches the actual switch hostname typo, kept verbatim so `show run` diffs clean).
          name = "Configure LAG xswoffce (id 15) - office switch uplink (real, SFP+)";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xswoffce dynamic id 15
               lacp-timeout short
               ports ethe 1/2/4 ethe 2/2/4
               force-up ethernet 1/2/4
               port-name xswoffice1 ethernet 1/2/4
               port-name xswoffice2 ethernet 2/2/4
            '';
          };
        }

        {
          name = "Configure LAG xswlab (id 13) - lab switch (static, no LACP)";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xswlab dynamic id 13
               ports ethe 1/1/46 ethe 2/1/46
               force-up ethernet 1/1/46
               port-name xswlab-a ethernet 1/1/46
               port-name xswlab-b ethernet 2/1/46
            '';
          };
        }

        {
          name = "Configure LAG xsvr1-vm (id 14) - xsvr1 VM traffic";
          "ansible.netcommon.cli_config" = {
            config = ''
              lag xsvr1-vm dynamic id 14
               lacp-timeout short
               ports ethe 1/1/7 ethe 2/1/7
               force-up ethernet 1/1/7
               port-name xsvr1-vm-a ethernet 1/1/7
               port-name xsvr1-vm-b ethernet 2/1/7
            '';
          };
        }

        # =========================================================
        # VLANs
        # =========================================================

        # STP standardization (2026-08-04): every VLAN now runs RSTP (802.1w), and every
        # VLAN's instance gets an explicit low bridge priority so xswcore always wins root
        # election — verified live that VLAN 19 (legacy 802.1D, no priority set) had ALREADY
        # lost root to the RF-cabinet Omada switch (bridge 800040ae30cb1106, OUI=TP-Link)
        # purely on MAC tiebreak. Priority 4096 is well below the 32768 default and below
        # any unmanaged/default-priority downstream switch, with headroom left below it.
        # Dead port refs (1/1/4, 1/1/44, and the orphaned lag11/lag12 member ports
        # 1/1/47-48 / 2/1/47-48, all confirmed link-down/disabled live) are dropped from
        # every VLAN's tagged/untagged membership. The real office uplink is lag 15 (see
        # LINK AGGREGATION section) — VLAN membership below matches live exactly.
        {
          name = "Configure VLAN 10 (FW - firewall transit)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 10 name FW by port
               tagged lag 1 to 2 lag 10
               untagged ethe 1/1/37 ethe 1/1/45 ethe 2/1/45
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Create VLAN 11 (unconfigured placeholder)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 11 by port
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 14 (management)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 14 name management by port
               tagged ethe 1/1/5 lag 6 lag 10 lag 15
               untagged ethe 1/1/2 ethe 1/1/13 to 1/1/14 ethe 2/1/1 to 2/1/2 ethe 2/1/13
               router-interface ve 14
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 15 (Printers)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 15 name Printers by port
               tagged lag 10 lag 15
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 16 (telephony)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 16 name telephony by port
               tagged lag 1 to 3 lag 10 lag 14 to 15
               untagged ethe 1/1/35 ethe 1/1/40 ethe 2/1/3 ethe 2/1/20 to 2/1/25
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 17 (HomeAutomation)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 17 name HomeAutomation by port
               tagged lag 1 to 3 lag 6 lag 10 lag 14 to 15
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 18";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 18 by port
               tagged lag 10
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          # This is the VLAN confirmed live (2026-08-04) to have already lost root to the
          # RF-cabinet Omada switch under the old plain "spanning-tree" (802.1D) config.
          name = "Configure VLAN 19 (provisioning)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 19 name provisioning by port
               tagged lag 10
               untagged ethe 1/1/5 lag 6 lag 15
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 20";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 20 by port
               tagged lag 10
               untagged lag 1 to 3
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 21 (HomeVMs)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 21 name HomeVMs by port
               tagged lag 1 to 3 lag 10 lag 14 to 15
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 22 (k8s)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 22 name k8s by port
               tagged lag 1 to 3 lag 10
               untagged ethe 2/1/36
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 100 (WiredClients)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 100 name WiredClients by port
               tagged lag 10 lag 15
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure WiFi VLANs (111/112/114/115) - tagged to rfcab, xfw";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan {{ item.id }} name {{ item.name }} by port
               tagged lag 6 lag 10
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
          loop = [
            { id = 111; name = "notthewifiyouarelookingfor"; }
            { id = 112; name = "WanIPlayWithMadness"; }
            { id = 114; name = "TotalEclipseOfTheUART"; }
            { id = 115; name = "HelloIsItWiFiYoureLookingFor"; }
          ];
        }

        {
          name = "Configure VLAN 1000 (Atlas)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 1000 name Atlas by port
               tagged ethe 1/1/11 ethe 2/1/44 lag 10
               untagged ethe 1/1/1
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLAN 2000 (xswlab untagged trunk)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 2000 by port
               tagged lag 10
               untagged lag 13
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        {
          name = "Configure VLANs 2001/2002/2004 (lab VLANs via xswlab)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan {{ item }} by port
               tagged ethe 1/1/24 lag 10 lag 13
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
          loop = [ "2001" "2002" "2004" ];
        }

        {
          name = "Configure VLAN 4000 (DEFAULT-VLAN)";
          "ansible.netcommon.cli_config" = {
            config = ''
              vlan 4000 name DEFAULT-VLAN by port
               spanning-tree 802-1w
               spanning-tree 802-1w priority 4096
            '';
          };
        }

        # =========================================================
        # INTERFACES
        # =========================================================

        {
          name = "Configure interface port-names";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ethernet {{ item.intf }}
               port-name {{ item.name }}
            '';
          };
          loop = [
            { intf = "1/1/1";  name = "atlas"; }
            { intf = "1/1/2";  name = "KVM"; }
            { intf = "1/1/13"; name = "xsvr1-mgmt"; }
            { intf = "1/1/14"; name = "xsvr3-mgmt"; }
            { intf = "1/1/25"; name = "xsvr1_impi"; }
            { intf = "1/1/26"; name = "xsvr2_impi"; }
            { intf = "1/1/27"; name = "xsvr3_ipmi"; }
            { intf = "1/1/43"; name = "xfw-temp-a"; }
            { intf = "2/1/1";  name = "RackUPS"; }
            { intf = "2/1/2";  name = "JetKVM"; }
            { intf = "2/1/13"; name = "xsvr2-mgmt"; }
          ];
        }

        {
          # 1/1/4 (xswlab access port) and 1/1/44 (UplinkToOfficeSwitch) confirmed
          # disconnected by the user 2026-08-04 — dropped from all VLANs above, disabled here.
          # 1/1/47-48 / 2/1/47-48 are the orphaned members of the old lag11/lag12 (both
          # already gone from live running-config, never actually reached by any LAG task
          # above) — confirmed link-down/admin-disabled live; disabled explicitly here so
          # they don't silently come up as untagged default-VLAN access ports.
          name = "Disable unused/reserved/dead interfaces";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ethernet {{ item }}
               disable
            '';
          };
          loop = [ "1/1/4" "1/1/8" "1/1/9" "1/1/43" "1/1/44" "1/1/47" "1/1/48" "2/1/8" "2/1/9" "2/1/47" "2/1/48" ];
        }

        # =========================================================
        # STP HARDENING (2026-08-04)
        # =========================================================
        # admin-edge-port: skip STP listen/learn delay on ports that never have another
        # bridge behind them (applies across all VLANs the port/LAG participates in).
        # stp-bpdu-guard: err-disable the port if it ever receives a BPDU — scoped only to
        # the server LAGs, where the far end is verified STP=false Linux bridges (see
        # nix/hosts/nixos/{xsvr1,xsvr2,xsvr3}/network.nix), plus the single-purpose infra
        # ports (IPMI/KVM/UPS) — deliberately NOT applied to phone/FW-transit/Atlas ports,
        # where there's less certainty nothing switch-like is ever patched in.
        # root-protect: refuse to become root port here, guaranteeing xswcore stays root
        # even if a downstream switch's priority/MAC would otherwise win — this is the
        # direct fix for the VLAN 19 root loss to the RF-cabinet switch found live.

        {
          name = "Mark server-facing LAGs as edge ports (all VLANs)";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface lag {{ item }}
               spanning-tree 802-1w admin-edge-port
               stp-bpdu-guard
            '';
          };
          loop = [ "1" "2" "3" "14" ];
        }

        {
          name = "Mark single-purpose infra access ports as edge ports with BPDU guard";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ethernet {{ item }}
               spanning-tree 802-1w admin-edge-port
               stp-bpdu-guard
            '';
          };
          loop = [ "1/1/2" "2/1/1" "2/1/2" "1/1/25" "1/1/26" "1/1/27" ];
        }

        {
          name = "Mark remaining known-edge access ports (admin-edge-port only, no bpdu-guard)";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ethernet {{ item }}
               spanning-tree 802-1w admin-edge-port
            '';
          };
          loop = [
            "1/1/1" "1/1/11" "1/1/13" "1/1/14" "1/1/35" "1/1/37" "1/1/40" "1/1/45"
            "2/1/3" "2/1/13" "2/1/20" "2/1/21" "2/1/22" "2/1/23" "2/1/24" "2/1/25"
            "2/1/36" "2/1/44" "2/1/45"
          ];
        }

        {
          name = "Enable root-guard on downstream-switch-facing LAGs (rfcab/xswlab/xswoffce)";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface lag {{ item }}
               spanning-tree root-protect
            '';
          };
          loop = [ "6" "13" "15" ];
        }

        {
          name = "Configure legacy PoE interfaces (pre-802.3af devices)";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ethernet {{ item }}
               legacy-inline-power
            '';
          };
          loop = [ "1/1/35" "1/1/45" ];
        }

        {
          name = "Disable inline power on individual ports";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ethernet {{ item }}
               no inline power
            '';
          };
          loop = [ "1/1/40" "2/1/29" ];
        }

        {
          name = "Disable inline power on xswlab LAG members (1/1/46, 2/1/46)";
          "ansible.netcommon.cli_config" = {
            config = "no inline power ethernet 1/1/46 ethernet 2/1/46";
          };
        }

        # =========================================================
        # LAYER 3
        # =========================================================

        {
          name = "Configure management VE 14 IP address";
          "ansible.netcommon.cli_config" = {
            config = ''
              interface ve 14
               ip address 172.18.4.100 255.255.255.0
            '';
          };
        }

        {
          name = "Configure default route via xfw";
          "ansible.netcommon.cli_config" = {
            config = "ip route 0.0.0.0/0 172.18.4.250";
          };
        }

        # =========================================================
        # SAVE
        # =========================================================

        {
          name = "Save running configuration to startup-config";
          "ansible.netcommon.cli_command" = {
            command = "write memory";
          };
        }

      ]; # end tasks
    }
  ]; # end playbook
}

# Summary: NixOS module for Keepalived, configures high-availability IP failover for cluster nodes.
{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  # Define node-specific configurations
  nodeConfigs = {
    xsvr1 = {
      ip = "172.20.3.201";
      keepalivedState = "MASTER";
      keepalivedPriority = 101;
    };
    xsvr2 = {
      ip = "172.20.3.202";
      keepalivedState = "BACKUP";
      keepalivedPriority = 100;
    };
    xsvr3 = {
      ip = "172.20.3.203";
      keepalivedState = "BACKUP";
      keepalivedPriority = 99;
    };
  };

  vipAddress = "172.20.3.200";
  gatewayVipAddress = "172.20.1.101";
  kanidmVipAddress = "172.20.1.110";

  # Only set currentNode if hostname is in nodeConfigs
  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;
in

if currentNode == null then
  { }
else
  {

    environment.etc."check-tailscale-subnet.sh" = {
      text = ''
        #!/bin/sh
        tailscale status --json | grep '"AdvertisedRoutes":' | grep '172.16.0.0/12' > /dev/null
        if [ $? -eq 0 ]; then
          exit 0
        else
          exit 1
        fi
      '';
      mode = "0755";
    };

    # Define the script for keepalived to reference
    services.keepalived = {
      enable = true;
      vrrpScripts = {
        check_tailscale_subnet = {
          script = "/etc/check-tailscale-subnet.sh";
          interval = 2;
          weight = -2;
          fall = 3;
          rise = 2;
        };
      };
      vrrpInstances = {
        k8s-gateway = {
          state = currentNode.keepalivedState;
          interface = "bridge22";
          virtualRouterId = 51;
          priority = currentNode.keepalivedPriority;
          virtualIps = [
            { addr = "${vipAddress}/24"; }
          ];
          extraConfig = ''
            authentication {
              auth_type PASS
              auth_pass k8svip
            }
            track_script {
              check_tailscale_subnet
            }
            notify_master "/run/current-system/systemd/bin/systemctl restart frr"
          '';
        };
        network-gateway = {
          state = currentNode.keepalivedState;
          interface = "bond0";
          virtualRouterId = 52;
          priority = currentNode.keepalivedPriority;
          virtualIps = [
            {
              addr = "${gatewayVipAddress}/24";
              dev = "bond0";
              label = "bond0:vip1";
            }
          ];
          extraConfig = ''
            authentication {
              auth_type PASS
              auth_pass networksvip
            }
            track_script {
              check_tailscale_subnet
            }
            notify_master "/run/current-system/systemd/bin/systemctl restart frr"
          '';
        };
        kanidm-idm = {
          state = currentNode.keepalivedState;
          interface = "bond0";
          virtualRouterId = 53;
          priority = currentNode.keepalivedPriority;
          virtualIps = [
            {
              addr = "${kanidmVipAddress}/24";
              dev = "bond0";
              label = "bond0:vip2";
            }
          ];
          extraConfig = ''
            authentication {
              auth_type PASS
              auth_pass kanidmvip
            }
            track_script {
              check_tailscale_subnet
            }
            notify_master "/run/current-system/systemd/bin/systemctl restart kanidm"
          '';
        };
      };
    };

    # Open required ports in firewall for VRRP
    networking.firewall = {
      extraCommands = ''
        # Allow VRRP multicast
        iptables -A INPUT -d 224.0.0.18/32 -j ACCEPT
        iptables -A OUTPUT -d 224.0.0.18/32 -j ACCEPT
      '';
    };
  }

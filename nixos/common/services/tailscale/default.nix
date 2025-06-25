{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  ...
}:
let
  tsClients = [ ];
  tsExitNodes = [ "xsvr1" "xsvr2" "xsvr3" ];

  # Assign a static IP for each host
  containerIPs = {
    xsvr1 = "172.20.21.201";
    xsvr2 = "172.20.21.202";
    xsvr3 = "172.20.21.203";
  };
in
{
  config = lib.mkMerge [

    (lib.mkIf (lib.elem "${hostname}" tsClients) {
      environment.systemPackages = with pkgs; lib.optionals isWorkstation [ trayscale ];
      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--operator=${username} --accept-routes"
        ];
        extraSetFlags = [
          "--operator=${username} --accept-routes"
        ];
      };
    })
    (lib.mkIf (lib.elem "${hostname}" tsExitNodes) {

      services.networkd-dispatcher = {
        enable = true;
        rules."99-ts-gro" = {
          onState =  [ "routable" ];
          script = ''
            if [ "$IFACE" = "bond0.21" ]; then
              ethtool -K bond0 rx-udp-gro-forwarding on rx-gro-list off
            fi
          '';
        };
      };

      containers.tailscale = {
        autoStart = true;
        restartIfChanged = true;
        privateNetwork = false;
        extraVeths = {
          eth0 = {
            hostBridge = "bridge21";
          };
        };
        additionalCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW"];
        config = { config, pkgs, lib, ... }: {
          environment.systemPackages = with pkgs; [
            tailscale
            ethtool
          ];
          services.tailscale = {
            enable = true;
            extraUpFlags = [
              "--advertise-exit-node"
              "--accept-routes"
              "--advertise-routes=172.16.0.0/12"
              "--snat-subnet-routes=false"
            ];
            openFirewall = true;
            useRoutingFeatures = "both";
          };
          networking.firewall.checkReversePath = "loose";

          system.stateVersion = "25.05";

          networking = {
            useDHCP = false;
            interfaces.eth0.ipv4.addresses = [
              { address = containerIPs.${hostname}; prefixLength = 24; }
            ];
            defaultGateway = "172.20.21.250";
            nameservers = [ "172.18.10.250" ];
            firewall.enable = false;
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;
        };
      };
    })
    {
      services.keepalived = {
        enable = true;
        vrrpInstances = {
          tailscale-vip = {
            interface = "eth0";
            virtualRouterId = 51;
            priority = if hostname == "xsvr1" then 101 else if hostname == "xsvr2" then 100 else 99;
            state = if hostname == "xsvr1" then "MASTER" else "BACKUP";
            virtualIps = [
              { addr = "172.20.21.200/24"; }
            ];
          };
        };
      };
    }
  ];
}






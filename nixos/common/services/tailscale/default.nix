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
    xsvr1 = "172.20.2.201";
    xsvr2 = "172.20.2.202";
    xsvr3 = "172.20.2.203";
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

      virtualisation.podman-containers.containers.tailscale = {
        image = "tailscale/tailscale:latest";
        security.allowPrivileged = true;
        network = "host";
        volumes = [
          "/dev/net/tun:/dev/net/tun"
          "/var/lib/tailscale:/var/lib/tailscale"
        ];
        environment = {
          # Optionally, set TS_AUTHKEY or other env vars here
          # TS_AUTHKEY = "your-auth-key";
        };
        cmd = [
          "/bin/sh"
          "-c"
          ''
            tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock &
            sleep 2
            tailscale up --advertise-exit-node --accept-routes --advertise-routes=172.16.0.0/12 --snat-subnet-routes=false
            wait
          ''
        ];
        restartPolicy = "always";
      };
    })
  ];
}






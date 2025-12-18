# Summary: Unified Tailscale VPN module supporting client, server, and exit node configurations.
{
  hostname,
  hostRoles ? [ ],
  isWorkstation ? false,
  lib,
  pkgs,
  username,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Role-based configuration - roles come from flake.nix host definitions
  isPackageOnly = lib.elem "tailscale-package" hostRoles;
  isClient = lib.elem "tailscale-client" hostRoles;
  isExitNode = lib.elem "tailscale-exit-node" hostRoles;

  enableTailscale = isPackageOnly || isClient || isExitNode;
in
{
  config = lib.mkMerge [
    # Package-only configuration (for hosts that need tailscale CLI but manage service externally)
    (lib.mkIf (enableTailscale && isPackageOnly) {
      environment.systemPackages = with pkgs; [ tailscale ];
    })

    # Standard client configuration
    (lib.mkIf (enableTailscale && isClient) {
      services.tailscale = lib.mkMerge [
        { enable = true; }
        # Only on NixOS hosts (Darwin doesn't support these options)
        (lib.mkIf (!isDarwin) {
          extraUpFlags = [
            "--operator=${username}"
            "--accept-routes"
          ];
          extraSetFlags = [
            "--operator=${username}"
            "--accept-routes"
          ];
        })
      ];

      environment.systemPackages =
        with pkgs;
        [
          tailscale
        ]
        ++ lib.optionals isWorkstation [ trayscale ];
    })

    # Exit node configuration (NixOS only)
    (lib.mkIf (enableTailscale && isExitNode) {
      environment.systemPackages = with pkgs; [
        tailscale
        ethtool
        networkd-dispatcher
        keepalived
      ];

      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--advertise-exit-node"
          "--accept-routes"
          "--advertise-routes=172.16.0.0/12"
          "--snat-subnet-routes=false"
          "--operator=${username}"
        ];
        openFirewall = true;
        useRoutingFeatures = "both";
      };

      networking.firewall.checkReversePath = "loose";

      services.networkd-dispatcher = {
        enable = true;
        rules."99-tailscale" = {
          onState = [ "routable" ];
          script = ''
            #!/bin/sh
            NIC=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')
            ethtool -K "$NIC" rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };

      services.keepalived = {
        enable = true;
        vrrpInstances = {
          ts-vip = {
            interface = "eth0";
            virtualRouterId = 51;
            priority =
              if hostname == "xts1" then
                101
              else if hostname == "xts2" then
                100
              else
                99;
            state = if hostname == "xts1" then "MASTER" else "BACKUP";
            virtualIps = [
              { addr = "172.18.10.100/24"; }
            ];
          };
        };
      };
    })
  ];
}

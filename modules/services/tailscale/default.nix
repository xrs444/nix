# Summary: Unified Tailscale VPN module supporting client and package-only configurations.
{
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

  enableTailscale = isPackageOnly || isClient;
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
  ];
}

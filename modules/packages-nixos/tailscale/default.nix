{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:
let
  # Define which hosts should have Tailscale client functionality  
  tsClients = [ "xsvr1" "xsvr2" "xsvr3" "xtl1-t-nixos" "xlt1-t" ];
  
  # Only apply to NixOS clients
  enableTailscale = lib.elem "${hostname}" tsClients;
  
in
{
  config = lib.mkIf enableTailscale {
    # NixOS-specific Tailscale configuration
    # Most configuration is handled by the common module
    # This module can be extended for NixOS-specific features
    
    # Example: NixOS-specific firewall rules if needed
    # networking.firewall.allowedUDPPorts = [ 41641 ];
  };
}
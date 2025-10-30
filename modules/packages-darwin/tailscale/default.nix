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
  
  # Only apply to Darwin clients
  enableTailscale = lib.elem "${hostname}" tsClients;
  
in
{
  config = lib.mkIf enableTailscale {
    # Darwin-specific Tailscale configuration
    # Most configuration is handled by the common module
    
    # Ensure Tailscale package is available
    environment.systemPackages = with pkgs; [ tailscale ];
    
    # Darwin-specific notes and limitations
    # - Exit node functionality requires manual configuration
    # - Advanced networking features not available through nix-darwin
    # - Firewall rules must be managed manually or through macOS preferences
  };
}
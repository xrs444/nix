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

    # Ensure Tailscale package is available
    environment.systemPackages = with pkgs; [ tailscale ];
    
  };
}
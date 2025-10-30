{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  platform,
  ...
}:
let
  # Define which hosts should have Tailscale client functionality
  tsClients = [ "xsvr1" "xsvr2" "xsvr3" "xtl1-t-nixos" "xlt1-t" ];
  
  # Common configuration for all Tailscale clients
  enableTailscale = lib.elem "${hostname}" tsClients;
  
in
{
  config = lib.mkIf enableTailscale {
    # Common Tailscale client configuration
    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--operator=${username}"
        "--accept-routes"
      ];
      extraSetFlags = [
        "--operator=${username}"
        "--accept-routes"
      ];
    };
    
    # Add GUI client for workstations
    environment.systemPackages = with pkgs; 
      lib.optionals isWorkstation [ trayscale ];
  };
}
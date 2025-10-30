{ pkgs, ... }:

{
  # Export individual modules
  cockpit = import ./cockpit;
  comin = import ./comin;
  tailscale = import ./tailscale;
  
  # Or create a combined module
  default = { pkgs, ... }: {
    imports = [
      ./cockpit
      ./comin
      ./tailscale
    ];

    # NixOS-specific packages
    environment.systemPackages = with pkgs; [
      # Add NixOS-specific packages here
    ];
  };
}
{ pkgs, ... }:

{
  # Export individual modules
  cockpit = import ./cockpit;
  comin = import ./comin;
  tailscale = import ./tailscale;
  
  # Combined module
  default = { config, lib, pkgs, ... }: {
    imports = [
      (import ./cockpit)
      (import ./comin)
      (import ./tailscale)
    ];

    # NixOS-specific packages
    environment.systemPackages = with pkgs; [
      # Add NixOS-specific packages here
    ];
  };
}
# Summary: NixOS module for workstation-specific packages, adds custom system packages for desktop environments.
{ pkgs, ... }:

{
  # Workstation-specific packages
  environment.systemPackages = with pkgs; [
    # Add workstation packages here
  ];
}

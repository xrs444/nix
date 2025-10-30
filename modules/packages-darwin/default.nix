{ pkgs, ... }:

{
  imports = [
    ../packages-common/kanidm
    ./tailscale
  ];

  # Darwin-specific packages
  environment.systemPackages = with pkgs; [
    # Add Darwin packages here
    
    # Additional tools that might be useful for kanidm on Darwin
    openssh
  ];
}